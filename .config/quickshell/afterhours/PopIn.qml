import QtQuick
// How every card under the rail opens: it grows out of what you clicked,
// from 92 % to a hair past full size and back (Theme.spring), while it
// fades in; its contents follow 60 ms later. Set the box's
// transformOrigin to the side that touches the rail.
ParallelAnimation {
    id: pop
    required property Item surface
    required property Item inner
    NumberAnimation { target: pop.surface; property: "opacity"; from: 0; to: 1; duration: Theme.glide; easing.type: Easing.OutCubic }
    NumberAnimation { target: pop.surface; property: "scale"; from: 0.92; to: 1; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot }
    SequentialAnimation {
        PropertyAction { target: pop.inner; property: "opacity"; value: 0 }
        PauseAnimation { duration: 60 }
        NumberAnimation { target: pop.inner; property: "opacity"; to: 1; duration: Theme.glide; easing.type: Easing.OutCubic }
    }
}
