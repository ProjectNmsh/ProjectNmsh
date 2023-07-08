// CRED: https://stackoverflow.com/questions/6150289/how-can-i-convert-an-image-into-base64-string-using-javascript/20285053#20285053
function toDataUrl(url, callback) {
    var xhr = new XMLHttpRequest();
    xhr.onload = function() {
        var reader = new FileReader();
        reader.onloadend = function() {
            callback(reader.result);
        }
        reader.readAsDataURL(xhr.response);
    };
    xhr.open("GET", url);
    xhr.responseType = "blob";
    xhr.send();
}

function sendBase64Server(data) {
    toDataUrl(data.img, function(base64) {
        fetch(`https://${GetParentResourceName()}/base64`, {
            method: "POST",
            headers: {"Content-Type": "application/json; charset=UTF-8"},
            body: JSON.stringify({
                base64: base64,
                handle: data.handle,
                id: data.id
            })
        });
    });
}
