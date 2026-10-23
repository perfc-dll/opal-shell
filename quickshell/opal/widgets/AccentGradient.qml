import QtQuick
import qs.config

// pink -> violet -> cyan, the Opal signature sweep.
Gradient {
    property real strength: 1.0
    orientation: Gradient.Horizontal
    GradientStop { position: 0.0; color: Theme.alpha(Theme.pink, strength) }
    GradientStop { position: 0.55; color: Theme.alpha(Theme.violet, strength) }
    GradientStop { position: 1.0; color: Theme.alpha(Theme.cyan, strength) }
}
