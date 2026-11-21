using Toybox.WatchUi;

class WimHofDelegate extends WatchUi.BehaviorDelegate {
    private var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() {
        _view.advance();
        return true;
    }

    function onBack() {
        return _view.back();
    }
}
