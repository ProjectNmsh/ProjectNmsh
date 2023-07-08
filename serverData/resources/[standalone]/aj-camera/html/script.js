Decorations = {}

var houseCategorys = {};

var selectedObject = null;

var selectedObjectData = null;

$(".container").hide();

$('document').ready(function() {
    window.addEventListener('message', function(event) {
        var item = event.data;

        if (item.type == "frontcam") {
            if (item.toggle) {
                $("#house-cam").fadeIn(150);
                $("#cam-label").html(item.label);
                $("#cam-type").html(item.idfk);
                $("#cam-connection").html(item.connection)
            } else {
                $("#house-cam").fadeOut(150)
            }
        }
    })
})