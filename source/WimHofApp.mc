using Toybox.Application;

class WimHofApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new WimHofView();
        return [view, new WimHofDelegate(view)];
    }
}
