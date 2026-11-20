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
  name: "ServiceProtocol"

  // Deleting keys from the object being iterated only loses entries once the
  // object is big enough: on Qt 6.8.3 a pristine object of 255 keys or fewer
  // is emptied completely, and above that the loop stops early — 360 keys
  // leaves 105 behind, 434 leaves 179. So a scene that builds a small
  // container passes whether or not the bug is there.
  //
  // Every count below is deliberately well past that, and each test builds its
  // own tree large enough on its own rather than relying on what an earlier
  // test left in the index.
  readonly property int leakThreshold: 255
  readonly property int nodesPerTree: 400

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

  // Emptying a container has to take every node under it out of the index.
  // commitNodeIndex deleted from the object it was iterating, and a for-in
  // skips entries it has not reached yet once the object is mutated, so most
  // of a replaced subtree stayed live — 255 of 360 nodes on a real showcase
  // page. The next time that page was built its ids collided with their own
  // ghosts, the replacement was refused, and because Ruby advances its own
  // last_children before the client answers it never resent: the page stayed
  // blank for the rest of the run.
  //
  // The count has to be large enough for the skipping to show. It does not
  // appear at all with a handful of nodes.
  function test_emptying_a_container_removes_every_node_under_it() {
    verify(nodesPerTree > leakThreshold,
           "a container this small cannot leak, so this test would pass either way")

    var children = []
    for (var i = 0; i < nodesPerTree; i++) children.push(chip("leaf." + i, "v" + i))
    render(container("root", [container("page", children)]))
    compare(service.lastError, "", "the render itself was refused")
    compare(service.nodeFor("leaf.0").props.text, "v0")

    replaceChildren("page", [])
    compare(service.lastError, "", "emptying the container was refused")

    var survivors = []
    for (var s = 0; s < nodesPerTree; s++) if (service.nodeFor("leaf." + s) !== null) survivors.push("leaf." + s)
    compare(survivors.length, 0, "these nodes outlived the container that held them: " +
            survivors.slice(0, 8).join(", "))
  }

  // ...which is what makes re-entering a page work. This is the user-visible
  // shape of the bug: open a page, leave it, come back, and the body is blank.
  function test_a_page_can_be_entered_again_after_being_left() {
    // Shaped like a real page, and 440 nodes so it is past the threshold on
    // its own. At 20 rows this passed on the unfixed code, which is exactly
    // the trap the threshold describes.
    function build(tag) {
      var rows = []
      for (var row = 0; row < 40; row++) {
        var cells = []
        for (var cell = 0; cell < 10; cell++)
          cells.push(chip("page.row." + row + ".chip." + cell, tag + row + "-" + cell))
        rows.push(container("page.row." + row, cells))
      }
      return rows
    }

    render(container("root", [container("page", build("a"))]))
    compare(service.lastError, "", "the render itself was refused")

    replaceChildren("page", [])
    compare(service.lastError, "", "leaving the page was refused")

    // a dynamic's scoped ids are deterministic, so returning rebuilds exactly
    // the same ids it used before
    replaceChildren("page", build("b"))
    compare(service.lastError, "", "returning to the page was refused")
    compare(service.nodeFor("page.row.0.chip.0").props.text, "b0-0", "the page did not come back")
    compare(service.nodeFor("page.row.39.chip.9").props.text, "b39-9", "the page came back only in part")
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
