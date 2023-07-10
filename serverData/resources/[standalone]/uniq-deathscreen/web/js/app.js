let CurrentTimer = 0;
var timerId
let isDead = false

window.addEventListener('message', function(event) {
    let item = event.data;
    if (item.type === "show") {
        if (item.status == true) {
            isDead = true;
            CurrentTimer = 0;
            $('#wrapper').fadeIn();
            $('#call_emergency').removeClass("disabled");
        } else {
            CurrentTimer = 0;
            $('#time').text('00:00');
            isDead = false;
            $("#wrapper").fadeOut();
        }
    } else if (item.type == 'setUPValues'){
        if (item.killer != null) killer.innerHTML = item.killer;
        clearTimeout(timerId);
        timerId = setInterval(timer, 1000);
        CurrentTimer = item.timer;
    }
});

function timer(){
    if (isDead) {
        if (CurrentTimer < 0) {
            $("#wrapper").fadeOut();
            $.post(`https://${GetParentResourceName()}/time_expired`);
            clearTimeout(timerId);
            CurrentTimer = 0
            isDead = false
        } else {
            $('#time').text(new Date(CurrentTimer * 1000).toISOString().substr(14, 5));
            CurrentTimer = CurrentTimer - 1;
        };
    }
};

$(function () {
    $('#accept_to_die').click(function () {
        $.post(`https://${GetParentResourceName()}/accept_to_die`);
    });

    $('#call_emergency').click(function () {
        $.post(`https://${GetParentResourceName()}/call_emergency`);
        $('#call_emergency').addClass('disabled');
    });

    // Add this section for the "Call AI Doc" button
    $('#call_ai_doc').click(function () {
        console.log("Call AI Doc button clicked"); // Add this line for debugging
        $.post(`https://${GetParentResourceName()}/call_ai_doc`, JSON.stringify({}));
    });

    $('#wrapper').hide();
});