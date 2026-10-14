.pragma library

// Paths, URIs and labels for the file widgets (Files, Screenshots, Shelf, Send).

function pathFromUrl(url) {
    var s = String(url || "");
    if (s.indexOf("file://") === 0) {
        s = s.slice(7);
        try {
            s = decodeURIComponent(s);
        } catch (e) {
        }
    }
    return s;
}

// A file:// URI another app accepts: encoded, with # and ? escaped too.
function fileUri(path) {
    return "file://" + encodeURI(String(path || "")).replace(/#/g, "%23").replace(/\?/g, "%3F");
}

// Paths from a drop (urls, or a text/uri-list), deduplicated.
function dedupe(paths) {
    var seen = {};
    var out = [];
    for (var i = 0; i < (paths || []).length; i++) {
        var p = pathFromUrl(paths[i]);
        if (!p || seen[p])
            continue;
        seen[p] = true;
        out.push(p);
    }
    return out;
}
