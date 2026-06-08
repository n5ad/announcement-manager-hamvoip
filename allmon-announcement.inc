<div>
<?php
// allmon-announcement-hamvoip.inc
// Clean version for HamvoIP - No Piper TTS
// Includes MP3 Upload + Polite/Priority + Scope support
if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
    return;
}
?>
<hr style="margin-top:30px;">
<div id="bottom_cron_section" style="margin-top:20px;">

    <h3>MP3 Upload</h3>
    <input type="file" id="mp3_upload" accept=".mp3,.wav" style="margin-bottom:8px;">
    <button id="upload_btn" class="submit">Upload to /mp3/</button>
    <div id="upload_status" style="margin-top:10px; font-weight:bold;"></div>

    <h3>Announcement Scheduler</h3>
    <select id="mp3_select" class="submit" style="border:2px solid #444; width: 280px;">
        <option value="">-- Select Audio File (MP3 or WAV) --</option>
    </select>
    <input type="button" class="submit" value="Install Announcement" id="install_announcement">
    <input type="button" class="submit" value="Delete MP3/WAV" id="delete_mp3" style="background:#dc3545;color:white;border:1px solid #c82333;">
    <input type="button" class="submit" value="Local Play" id="local_play_mp3" style="background:#28a745;color:white;border:1px solid #1e7e34;">
    <input type="button" class="submit" value="Global Play" id="global_play_mp3" style="background:#fd7e14;color:white;border:1px solid #e06b00;">
    <br><br>

    <select id="ul_select" class="submit" style="border:2px solid #444; width: 280px;">
        <option value="">-- Select .ul Announcement --</option>
    </select>
    <input type="button" class="submit" value="Play Now" id="run_ul">
    <input type="button" class="submit" value="Delete .ul" id="delete_ul" style="background:#dc3545;color:white;border:1px solid #c82333;">
    <br><br>

    <h3>Cron Manager</h3>
    <div style="overflow-x:auto; margin-top:10px;">
        <table id="cron_table" style="width:100%; border-collapse:collapse; border:1px solid #666; font-size:0.95em;">
            <thead style="background:#444;color:white;">
                <tr>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">Min</th>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">Hour</th>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">DOM</th>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">Mon</th>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">DOW</th>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">File</th>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">Scope</th>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">Description</th>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">Enabled</th>
                    <th style="padding:8px; border:1px solid #666; text-align:center;">Actions</th>
                </tr>
            </thead>
            <tbody></tbody>
        </table>
    </div>
</div>

<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script>
$(document).ready(function() {

    function loadMP3Dropdown() {
        $.getJSON("/supermon/custom/list_mp3.php", function(files) {
            $("#mp3_select").empty().append($("<option>").val("").text("-- Select Audio File (MP3/WAV) --"));
            $.each(files, function(i, f) {
                $("#mp3_select").append($("<option>").val(f).text(f));
            });
        });
    }
    loadMP3Dropdown();

    function loadULDropdown() {
        $.getJSON("/supermon/custom/list_ul.php", function(files) {
            $("#ul_select").empty().append($("<option>").val("").text("-- Select .ul Announcement --"));
            $.each(files, function(i, f) {
                $("#ul_select").append($("<option>").val(f).text(f));
            });
        });
    }
    loadULDropdown();

    // Upload
    $("#upload_btn").click(function() {
        let fileInput = $("#mp3_upload")[0];
        if (!fileInput.files.length) { alert("Please select a file first."); return; }
        let formData = new FormData();
        formData.append("file", fileInput.files[0]);
        $("#upload_status").text("Uploading...").css("color", "orange");
        $.ajax({
            url: "/supermon/custom/upload_mp3.php",
            type: "POST",
            data: formData,
            processData: false,
            contentType: false,
            success: function(r) {
                $("#upload_status").html(r).css("color", "green");
                loadMP3Dropdown();
            },
            error: function() { $("#upload_status").text("Upload failed.").css("color", "red"); }
        });
    });

    // Delete MP3
    $("#delete_mp3").click(function() {
        let f = $("#mp3_select").val();
        if (!f || !confirm("Delete " + f + "?")) return;
        $.post("/supermon/custom/delete_file.php", {type:"mp3", file:f}, function(r){
            alert(r); loadMP3Dropdown();
        });
    });

    // Local / Global Play
    $("#local_play_mp3").click(function() {
        let f = $("#mp3_select").val();
        if (!f) { alert("Select file"); return; }
        $.post("/supermon/custom/run_announcement.php", { file: f, source: "mp3" }, function(r){ alert(r); });
    });

    $("#global_play_mp3").click(function() {
        let f = $("#mp3_select").val();
        if (!f) { alert("Select file"); return; }
        if (!confirm("GLOBAL PLAY - Continue?")) return;
        $.post("/supermon/custom/globalplay.php", { file: f, source: "mp3" }, function(r){ alert(r); });
    });

    // UL buttons
    $("#run_ul").click(function() {
        let f = $("#ul_select").val();
        if (!f) { alert("Select .ul"); return; }
        $.post("/supermon/custom/run_announcement.php", { file: f, source: "ul" }, function(r){ alert(r); });
    });

    $("#delete_ul").click(function() {
        let f = $("#ul_select").val();
        if (!f || !confirm("Delete " + f + "?")) return;
        $.post("/supermon/custom/delete_file.php", {type:"ul", file:f}, function(r){ alert(r); loadULDropdown(); });
    });

    // Install with scope + mode
    $("#install_announcement").click(function() {
        let mp3 = $("#mp3_select").val();
        if (!mp3) { alert("Select MP3 file"); return; }

        let min = prompt("Minute:", "45"); if(min===null) return;
        let hour = prompt("Hour:", "7-20"); if(hour===null) return;
        let dom = prompt("DOM:", "*"); if(dom===null) return;
        let month = prompt("Month:", "*"); if(month===null) return;
        let dow = prompt("DOW:", "*"); if(dow===null) return;

        let week = "*"; let useNth = false;
        if (/^[1-7]$/.test(dow.trim())) {
            week = prompt("Week of month? (* or 1-5)", "*");
            if (week !== "*" && /^[1-5]$/.test(week)) useNth = true;
        }

        let desc = prompt("Description:", "Scheduled announcement");
        if (!desc || !desc.trim()) { alert("Description required."); return; }

        let scopeChoice = prompt("Scope? (local or global)", "local");
        let scope = (scopeChoice && scopeChoice.trim().toLowerCase() === "global") ? "global" : "local";
        if (scope === "global" && !confirm("GLOBAL - Proceed?")) return;

        let modeChoice = prompt("Mode? polite or priority", "polite");
        let mode = (modeChoice && modeChoice.trim().toLowerCase() === "priority") ? "priority" : "polite";

        $.post("/supermon/custom/announcement.php", {
            file: mp3, min, hour, dom, month, dow, week,
            use_nth: useNth ? 1 : 0, desc, scope: scope, mode: mode
        }, function(data) {
            alert(data);
            loadMP3Dropdown(); loadULDropdown(); loadCronList();
        }).fail(() => alert("Install failed."));
    });

    function loadCronList() {
        $.getJSON("/supermon/custom/list_cron.php", function(crons) {
            let table = $("#cron_table tbody").empty();
            crons.forEach(function(c) {
                let row = $("<tr>");
                let parts = c.time.split(" ");
                row.append($("<td>").text(parts[0] || "*"));
                row.append($("<td>").text(parts[1] || "*"));
                row.append($("<td>").text(parts[2] || "*"));
                row.append($("<td>").text(parts[3] || "*"));
                row.append($("<td>").text(parts[4] || "*"));
                row.append($("<td>").text(c.file));
                let scopeText = (c.scope || "local").toUpperCase();
                row.append($("<td>").text(scopeText).css({fontWeight:"bold", color: scopeText==="GLOBAL" ? "#fd7e14" : "#28a745"}));
                row.append($("<td>").text(c.desc || ""));
                let isEnabled = !c.raw.startsWith('#');
                let toggleBtn = $("<button>").text(isEnabled ? "Enabled" : "Disabled")
                    .css({backgroundColor: isEnabled?"#28a745":"#dc3545", color:"white", padding:"6px 12px", cursor:"pointer"})
                    .click(function(){
                        let newState = !isEnabled;
                        $.post("/supermon/custom/toggle_cron.php", {raw_line: c.raw, enable: newState?1:0}, function(d){alert(d); loadCronList();});
                    });
                row.append($("<td>").append(toggleBtn));

                let acts = $("<td>").css("white-space","nowrap");
                $("<button>").text("Play Now").click(() => $.post("/supermon/custom/run_announcement.php", {file:c.file}, r=>alert(r))).appendTo(acts);
                $("<button>").text("Edit").click(function(){
                    if (c.raw.includes("/bin/bash -c") && c.raw.includes("date +\\%d")) { alert("Cannot edit nth-week jobs"); return; }
                    let p = c.time.split(" ");
                    let min = prompt("Minute:",p[0]); if(min===null)return;
                    let hour = prompt("Hour:",p[1]); if(hour===null)return;
                    let dom = prompt("DOM:",p[2]); if(dom===null)return;
                    let month = prompt("Month:",p[3]); if(month===null)return;
                    let dow = prompt("DOW:",p[4]); if(dow===null)return;
                    $.post("/supermon/custom/update_announcement.php", {raw_line:c.raw,min,hour,dom,month,dow}, r=>{alert(r);loadCronList();});
                }).appendTo(acts);
                $("<button>").text("Delete").click(() => {
                    if(!confirm("Delete?")) return;
                    $.post("/supermon/custom/delete_announcement.php", {raw_line:c.raw}, r=>{alert(r);loadCronList();});
                }).appendTo(acts);
                row.append(acts);
                table.append(row);
            });
        });
    }
    loadCronList();
});
</script>
<style>
    .submit { padding:6px 12px; margin:4px; }
    #cron_table th, #cron_table td { border:1px solid #666; padding:8px; text-align:center; }
</style>
<?php } ?>
</div>
