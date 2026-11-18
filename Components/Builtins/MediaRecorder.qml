import QtQuick
import QtMultimedia
import "Support" as Support

Item {
  id:recorderRoot;property var renderer:null;property alias mediaRecorder:nativeRecorder;property int handledCommandRevision:-1;readonly property var sessionItem:renderer?renderer.findRenderedItem(renderer.prop("session","")):null
  function quality(){var value=String(renderer?renderer.prop("quality","normal"):"normal");if(value==="very_low")return MediaRecorder.VeryLowQuality;if(value==="low")return MediaRecorder.LowQuality;if(value==="high")return MediaRecorder.HighQuality;if(value==="very_high")return MediaRecorder.VeryHighQuality;return MediaRecorder.NormalQuality}
  function resolution(){var value=renderer?renderer.prop("resolution",[]):[];if(Array.isArray(value))return Qt.size(Number(value[0]||0),Number(value[1]||0));if(value&&typeof value==="object")return Qt.size(Number(value.width||0),Number(value.height||0));return Qt.size(0,0)}
  function fileFormat(){var value=String(renderer?renderer.prop("media_format","unspecified"):"unspecified").toLowerCase();var values={wmv:MediaFormat.WMV,avi:MediaFormat.AVI,matroska:MediaFormat.Matroska,mkv:MediaFormat.Matroska,mp4:MediaFormat.MPEG4,mpeg4:MediaFormat.MPEG4,m4a:MediaFormat.MPEG4,ogg:MediaFormat.Ogg,quicktime:MediaFormat.QuickTime,webm:MediaFormat.WebM,aac:MediaFormat.AAC,mp3:MediaFormat.MP3,flac:MediaFormat.FLAC,wave:MediaFormat.Wave,wav:MediaFormat.Wave};return values[value]===undefined?MediaFormat.UnspecifiedFormat:values[value]}
  function audioCodec(){var value=String(renderer?renderer.prop("audio_codec","unspecified"):"unspecified").toLowerCase();var values={mp3:MediaFormat.AudioCodec.MP3,aac:MediaFormat.AudioCodec.AAC,ac3:MediaFormat.AudioCodec.AC3,eac3:MediaFormat.AudioCodec.EAC3,flac:MediaFormat.AudioCodec.FLAC,opus:MediaFormat.AudioCodec.Opus,vorbis:MediaFormat.AudioCodec.Vorbis,wave:MediaFormat.AudioCodec.Wave,wma:MediaFormat.AudioCodec.WMA,alac:MediaFormat.AudioCodec.ALAC};return values[value]===undefined?MediaFormat.AudioCodec.Unspecified:values[value]}
  function videoCodec(){var value=String(renderer?renderer.prop("video_codec","unspecified"):"unspecified").toLowerCase();var values={mpeg1:MediaFormat.VideoCodec.MPEG1,mpeg2:MediaFormat.VideoCodec.MPEG2,mpeg4:MediaFormat.VideoCodec.MPEG4,h264:MediaFormat.VideoCodec.H264,h265:MediaFormat.VideoCodec.H265,vp8:MediaFormat.VideoCodec.VP8,vp9:MediaFormat.VideoCodec.VP9,av1:MediaFormat.VideoCodec.AV1,theora:MediaFormat.VideoCodec.Theora,wmv:MediaFormat.VideoCodec.WMV,motion_jpeg:MediaFormat.VideoCodec.MotionJPEG};return values[value]===undefined?MediaFormat.VideoCodec.Unspecified:values[value]}
  function send(name,payload){if(renderer&&renderer.subscribed(name))renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,name,payload||{})}
  // Every QMediaFormat enum starts at Unspecified = -1, so the name tables are indexed
  // from that, not from zero.
  readonly property var fileFormatNames: ["unspecified","wmv","avi","matroska","mpeg4","ogg","quicktime","webm","mpeg4_audio","aac","wma","mp3","flac","wave"]
  readonly property var audioCodecNames: ["unspecified","mp3","aac","ac3","eac3","flac","dolby_true_hd","opus","vorbis","wave","wma","alac"]
  readonly property var videoCodecNames: ["unspecified","mpeg1","mpeg2","mpeg4","h264","h265","vp8","vp9","av1","theora","wmv","motion_jpeg"]
  function namesFor(values,table){var names=[];for(var i=0;i<values.length;i++){var slot=Number(values[i])+1;names.push(table[slot]===undefined?String(values[i]):table[slot])}return names}
  function formatRequested(){
    return String(renderer.prop("media_format","unspecified"))!=="unspecified"||
           String(renderer.prop("audio_codec","unspecified"))!=="unspecified"||
           String(renderer.prop("video_codec","unspecified"))!=="unspecified"
  }
  // QMediaFormat is isCreatable: false; it reaches QML as MediaRecorder.mediaFormat, which
  // is also the only place its support tables can be asked for. Publishing them lets an
  // application pick a container and codecs the platform actually encodes.
  function publishFormats(){
    if(!renderer)return
    var format=nativeRecorder.mediaFormat
    var supported=format.isSupported(MediaFormat.Encode)===true
    send("formats",{
      encode_file_formats:namesFor(format.supportedFileFormats(MediaFormat.Encode),fileFormatNames),
      decode_file_formats:namesFor(format.supportedFileFormats(MediaFormat.Decode),fileFormatNames),
      encode_audio_codecs:namesFor(format.supportedAudioCodecs(MediaFormat.Encode),audioCodecNames),
      encode_video_codecs:namesFor(format.supportedVideoCodecs(MediaFormat.Encode),videoCodecNames),
      selected_supported:supported
    })
    // An all-unspecified format lets the backend choose, and Qt reports that as
    // unsupported, so only a format the application actually asked for is an error.
    if(!supported&&formatRequested())
      renderer.componentError("media_format_unsupported","The platform cannot encode the requested container and codecs",
        {file_format:String(renderer.prop("media_format","unspecified")),audio_codec:String(renderer.prop("audio_codec","unspecified")),video_codec:String(renderer.prop("video_codec","unspecified"))})
  }
  function connectSession(){if(sessionItem&&sessionItem.captureSession!==undefined)sessionItem.captureSession.recorder=nativeRecorder}
  function command(){if(!renderer)return;var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;handledCommandRevision=revision;var value=String(renderer.prop("command",""));if(value==="record")nativeRecorder.record();else if(value==="pause")nativeRecorder.pause();else if(value==="stop")nativeRecorder.stop()}
  MediaRecorder{id:nativeRecorder;outputLocation:renderer?renderer.assetUrl(renderer.prop("output_location","")):"";quality:recorderRoot.quality();videoResolution:recorderRoot.resolution();mediaFormat.fileFormat:recorderRoot.fileFormat();mediaFormat.audioCodec:recorderRoot.audioCodec();mediaFormat.videoCodec:recorderRoot.videoCodec();videoFrameRate:Number(renderer?renderer.prop("frame_rate",0):0);audioBitRate:Number(renderer?renderer.prop("audio_bit_rate",0):0);videoBitRate:Number(renderer?renderer.prop("video_bit_rate",0):0);onRecorderStateChanged:{var name=recorderState===MediaRecorder.RecordingState?"record":(recorderState===MediaRecorder.PausedState?"pause":"stop");recorderRoot.send(name,{})} onDurationChanged:recorderRoot.send("duration",{value:duration});onErrorOccurred:function(error,errorString){renderer.componentError("media_recording_failed",errorString,{native_code:error})} onActualLocationChanged:recorderRoot.send("location",{value:String(actualLocation)})
    onMetaDataChanged:recorderRoot.send("metadata",metaDataReader.payload(nativeRecorder.metaData))
  }
  Support.MediaMetaDataReader { id: metaDataReader }
  Component.onCompleted:{connectSession();command();publishFormats()}onSessionItemChanged:connectSession();Connections{target:renderer;function onNodeChanged(){recorderRoot.command()}}
}
