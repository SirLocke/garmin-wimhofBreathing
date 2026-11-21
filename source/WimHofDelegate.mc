using Toybox.WatchUi;
using Toybox.Lang;

class WimHofDelegate extends WatchUi.InputDelegate {
    private var _view;

    function initialize(view) {
        InputDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER) {
            _view.advance();
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            return _view.back();
        }
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        _view.advance();
        return true;
    }
}
