var highlighted = new Array();
function highlight()
{
    // clear existing highlights
    for (var i = 0; i < highlighted.length; i++) {
        var elm = document.getElementById(highlighted[i]);
        if (elm != null) {
            elm.style.backgroundColor = 'white';
        }
    }
    highlighted = new Array();
    for (var i = 0; i < arguments.length; i++) {
        var elm = document.getElementById(arguments[i]);
        if (elm != null) {
            elm.style.backgroundColor = '#dddddd';
        }
        highlighted.push(arguments[i]);
    }
}
