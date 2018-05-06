var highlighted;

function highlight(xid)
{
    var elms = document.querySelectorAll('[xid="' + xid + '"]');
    for (k in elms) {
        v = elms[k]
        v.className = "active";
    }
    highlighted = xid;
}

function clearHighlight() {
    var elms = document.querySelectorAll('[xid="' + highlighted + '"]');
    for (k in elms) {
        v = elms[k]
        v.className = "";
    }
}

window.onload =
    function (e) {
        var tags = document.getElementsByTagName("A")
        for (var i = 0; i < tags.length; i++) {
            tags[i].onmouseover =
                function (e) {
                    clearHighlight();
                    var xid = e.toElement.getAttribute('xid');
                    highlight(xid);
                }
        }
    }
