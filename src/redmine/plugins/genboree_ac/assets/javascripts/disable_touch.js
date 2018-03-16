if (!navigator.userAgent.match(/Android|BlackBerry|iPhone|iPad|iPod|Opera Mini|IEMobile/i)) {
    delete Window.prototype.ontouchend;
    delete window.ontouchend;
    var navigator;
    if ('maxTouchPoints' in Navigator.prototype) {
        navigator = Navigator.prototype;
    } else {
        navigator = Object.create(navigator);
        Object.defineProperty(window, 'navigator', {
            value: navigator,
            configurable: false,
            enumerable: false,
            writable: false
        });
    }
    Object.defineProperties(navigator, { maxTouchPoints: { value: 0, configurable: false, enumerable: true, writable: false } });
}