import QtQuick
import QtTest
import "../.."

// Service.qml works out which nodes a replace_children removes by walking the
// container's *stored* children array. That array is a snapshot from the last
// time this container was replaced, and it goes stale the moment a nested
// container is patched on its own — which is exactly what a nested `dynamic`
// does. The nodes the client really has are then never marked as removed, and
// the next replacement of the outer container is refused with
//
//   zui bridge: invalid children patch — node id already live at <id>
//
// Ruby has already advanced its own last_children by then and never resends,
// so that part of the interface silently stops updating for good.
TestCase {
  name: "ServiceStaleChildren"

  QtObject {
    id: fakeTransport
    property bool running: false
    function write(data) { return true }
    function start(executable, program, directory, loadPath) {}
    function stop() {}
    signal lineReceived(string line)
    signal errorLineReceived(string line)
    signal exited(int code)
  }

  Service { id: service; transport: fakeTransport }

  function definitions() {
    return {
      container: { qml: "Container.qml", properties: [], events: [],
                   property_map: {}, event_map: {}, container: true, built_in: true },
      chip: { qml: "Chip.qml", properties: ["text"], events: [],
              property_map: {}, event_map: {}, container: false, built_in: true }
    }
  }

  function render(tree) {
    service.handleLine(JSON.stringify({
      v: 1, type: "render", components: definitions(), surfaces: { main: tree }
    }))
  }

  function replaceChildren(id, children) {
    service.handleLine(JSON.stringify({
      v: 1, type: "patch", op: "replace_children", id: id, children: children
    }))
  }

  function chip(id, text) { return { type: "chip", id: id, props: { text: text } } }
  function container(id, children) { return { type: "container", id: id, children: children } }

  function init() { service.stopping = true }

  function test_an_outer_replacement_survives_a_nested_one() {
    render(container("root", [container("page", [container("inner", [chip("inner.chip.1", "a")])])]))
    compare(service.lastError, "", "the render itself was refused")

    // the nested container is patched on its own and comes back with a
    // different set of ids, which is what a nested dynamic produces
    replaceChildren("inner", [chip("inner.chip.2", "b")])
    compare(service.lastError, "", "the nested patch was refused")
    verify(service.nodeFor("inner.chip.2") !== null, "the nested patch did not install its child")
    verify(service.nodeFor("inner.chip.1") === null, "the nested patch left its old child live")

    // now the outer container is replaced with a tree that contains the node
    // the nested patch installed. Walking the stale snapshot never marks it as
    // removed, so it is still live and the whole patch is refused.
    replaceChildren("page", [container("inner", [chip("inner.chip.2", "c")])])
    compare(service.lastError, "", "the outer patch was refused")
    compare(service.nodeFor("inner.chip.2").props.text, "c", "the outer patch did not take effect")
  }

  // The same staleness, one level deeper, so the fix cannot just special-case
  // a container's immediate children.
  function test_staleness_is_followed_to_any_depth() {
    render(container("root", [container("page", [container("mid", [container("leaf", [chip("leaf.chip.1", "a")])])])]))
    compare(service.lastError, "", "the render itself was refused")

    replaceChildren("leaf", [chip("leaf.chip.2", "b")])
    compare(service.lastError, "", "the nested patch was refused")

    replaceChildren("page", [container("mid", [container("leaf", [chip("leaf.chip.2", "c")])])])
    compare(service.lastError, "", "the outer patch was refused")
  }
}
