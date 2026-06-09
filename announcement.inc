<?php
/**
 * announcement.inc
 *
 * HamvoIP Supermon Announcement Manager
 *
 * Author: N5AD (James Carnathan)
 *
 * Created: June 2026
 * Updated: June 2026
 *
 * Description:
 *   Main interface for the Announcement Manager on HamvoIP.
 *   Supports MP3 upload, conversion to .ul, scheduling, and playback.
 *
 * Note: This file is included after successful login.
 */
if (isset($_SESSION['sm61loggedin']) && $_SESSION['sm61loggedin'] === true) { 
?>
<hr style="margin-top:30px;">
<div id="bottom_cron_section" style="margin-top:20px;">
<h1>Announcement Management System</h1>

    <!-- MP3 Upload -->
    <h3>MP3/Wav Upload</h3>
    <input type="file" id="mp3_upload" accept=".mp3,.wav" style="margin-bottom:8px;">
    <button id="upload_btn" class="submit">Upload to mp3 directory</button>
    <div id="upload_status" style="margin-top:10px; font-weight:bold;"></div>

    <h3>Announcement Scheduler</h3>
    <select id="mp3_select" class="submit" style="border:2px solid #444; width: 250px;">
        <option value="">-- Select Audio File (MP3-WAV) --</option>
    </select>
    <input type="button" class="submit" value="Install Announcement" id="install_announcement">
    <input type="button" class="submit" value="Delete MP3" id="delete_mp3" style="background-color:#dc3545; color:white; border:1px solid #c82333;">

    <input type="button" class="submit" value="Convert to .ul" id="convert_mp3" style="background:#17a2b8;color:white;border:1px solid #138496;">
 <h5>you only need to convert if you want to play the file without installing it first</h5>
	

    <select id="ul_select" class="submit" style="border:2px solid #444; width: 250px;">
        <option value="">-- Select .ul Announcement --</option>
    </select>
    <input type="button" class="submit" value="Local Play" id="local_play_ul" style="background:#28a745;color:white;border:1px solid #1e7e34;">
    <input type="button" class="submit" value="Global Play" id="global_play_ul" style="background:#fd7e14;color:white;border:1px solid #e06b00;">
    <input type="button" class="submit" value="Delete UL" id="delete_ul" style="background-color:#dc3545; color:white; border:1px solid #c82333;">
    <br><br>

    <h3>Cron Manager</h3>
    <table id="cron_table" border="1" cellpadding="5" style="width:100%; border-collapse: collapse;">
        <thead>
            <tr>
                <th>Minute</th>
                <th>Hour</th>
                <th>Day of Month</th>
                <th>Month</th>
                <th>Day of Week</th>
                <th>Name of File</th>
                <th>Scope</th>
                <th>Description</th>
                <th>Enabled</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody></tbody>
    </table>
</div>

<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script>
$(document).ready(function () {

    function loadMP3Dropdown() {
        $.getJSON("custom/list_mp3.php", function(files) {
            $("#mp3_select").empty().append($("<option>").val("").text("-- Select Audio File (MP3-WAV) --"));
            files.forEach(function(f) {
                $("#mp3_select").append($("<option>").val(f).text(f));
            });
        });
    }
    loadMP3Dropdown();

    function loadULDropdown() {
        $.getJSON("custom/list_ul.php", function(files) {
            $("#ul_select").empty().append($("<option>").val("").text("-- Select Announcement --"));
            files.forEach(function(f) {
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
            url: "custom/upload_mp3.php",
            type: "POST",
            data: formData,
            processData: false,
            contentType: false,
            success: function(response) {
                $("#upload_status").html(response).css("color", "green");
                loadMP3Dropdown();
            },
            error: function() {
                $("#upload_status").text("Upload failed.").css("color", "red");
            }
        });
    });

    // Convert to .ul
    $("#convert_mp3").click(function() {
        let f = $("#mp3_select").val();
        if (!f) { alert("Select an MP3 or WAV file first"); return; }
        $.post("custom/convert_mp3.php", { file: f }, function(r){
            alert(r);
            loadULDropdown();
        }).fail(function() { alert("Conversion failed."); });
    });

    $("#delete_mp3").click(function() {
        let mp3 = $("#mp3_select").val();
        if (!mp3) { alert("Select an MP3 file."); return; }
        if (!confirm("Delete '" + mp3 + "'?")) return;
        $.post("custom/delete_file.php", { type: "mp3", file: mp3 }, function(data) {
            alert(data);
            loadMP3Dropdown();
        });
    });

    // UL Playback
    $("#local_play_ul").click(function() {
        let f = $("#ul_select").val();
        if (!f) { alert("Select a .ul file."); return; }
        $.post("/supermon/custom/run_announcement.php", { file: f, source: "ul" }, function(r){ alert(r); });
    });

    $("#global_play_ul").click(function() {
        let f = $("#ul_select").val();
        if (!f) { alert("Select a .ul file."); return; }
        if (!confirm("GLOBAL PLAY - Continue?")) return;
        $.post("/supermon/custom/globalplay.php", { file: f, source: "ul" }, function(r){ alert(r); });
    });

    $("#delete_ul").click(function() {
        let ul = $("#ul_select").val();
        if (!ul) { alert("Select a UL file."); return; }
        if (!confirm("Delete '" + ul + "'?")) return;
        $.post("custom/delete_file.php", { type: "ul", file: ul }, function(data) {
            alert(data);
            loadULDropdown();
        });
    });

    // Install Announcement (my original working code)
    $("#install_announcement").click(function() {
        let mp3 = $("#mp3_select").val();
        if (!mp3) { alert("Select an MP3 file."); return; }

        let min = prompt("Minute:", "45"); if(min===null) return;
        let hour = prompt("Hour:", "7-20"); if(hour===null) return;
        let dom = prompt("DOM:", "*"); if(dom===null) return;
        let month = prompt("Month:", "*"); if(month===null) return;
        let dow = prompt("DOW:", "*"); if(dow===null) return;

        let week = "*";
        let useNth = false;
        if (/^[1-7]$/.test(dow.trim())) {
            week = prompt("Week of month? (* or 1-5)", "*");
            if (week !== "*" && /^[1-5]$/.test(week)) useNth = true;
        }

        let desc = prompt("Description:", "Scheduled announcement");
        if (!desc || !desc.trim()) { alert("Description required."); return; }

        let scopeChoice = prompt("Scope? (local or global)", "local");
        let scope = (scopeChoice && scopeChoice.trim().toLowerCase() === "global") ? "global" : "local";
        if (scope === "global" && !confirm("GLOBAL PLAYBACK - Proceed?")) return;

        let modeChoice = prompt("Mode? (polite or priority)", "polite");
        let mode = (modeChoice && modeChoice.trim().toLowerCase() === "priority") ? "priority" : "polite";

        $.post("custom/announcement.php", {
            file: mp3,
            min, hour, dom, month, dow, week,
            use_nth: useNth ? 1 : 0,
            desc,
            scope: scope,
            mode: mode
        }, function(data) {
            alert(data);
            loadULDropdown();
            loadCronList();
            loadMP3Dropdown();
        }).fail(function() { alert("Install failed."); });
    });

    function loadCronList() {
        $.getJSON("custom/list_cron.php", function(crons) {
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
                row.append($("<td>").text(c.scope ? c.scope.toUpperCase() : "â€”"));
                row.append($("<td>").text(c.desc || ""));

                let isEnabled = !c.raw.startsWith('#');
                let toggleBtn = $("<button>")
                    .text(isEnabled ? "Enabled" : "Disabled")
                    .css({ "background-color": isEnabled ? "#28a745" : "#dc3545", "color": "white", "padding": "6px 12px", "cursor": "pointer" })
                    .click(function() {
                        let newState = !isEnabled;
                        if (!confirm(`Really ${newState ? "enable" : "disable"}?`)) return;
                        $.post("custom/toggle_cron.php", { raw_line: c.raw, enable: newState ? 1 : 0 }, function(data) {
                            alert(data);
                            loadCronList();
                        });
                    });

                let acts = $("<td>").css("white-space", "nowrap");

                // FIXED: Play Now respects scope
                let playBtn = $("<button>").text("Play Now")
                    .css({"background":"#28a745", "color":"white", "margin-right":"8px"})
                    .click(function(){
                        let scope = (c.scope && c.scope.toLowerCase() === 'global') ? 'global' : 'local';
                        if (!confirm("Play '" + c.file + "' now?\nScope: " + scope.toUpperCase())) return;

                        if (scope === 'global') {
                            $.post("/supermon/custom/globalplay.php", { file: c.file, source: "ul" }, function(r){ alert(r); });
                        } else {
                            $.post("/supermon/custom/run_announcement.php", { file: c.file, source: "ul" }, function(r){ alert(r); });
                        }
                    });

                let editBtn = $("<button>").text("Edit")
                    .css({"background":"#ffc107", "color":"black", "margin-right":"8px"})
                    .click(function(){
                        if (c.raw.includes("/bin/bash -c") && c.raw.includes("date +\\%d")) {
                            alert("Cannot edit nth-week jobs. Delete and recreate.");
                            return;
                        }
                        let p = c.time.split(" ");
                        let min = prompt("Minute:", p[0]); if(min===null) return;
                        let hour = prompt("Hour:", p[1]); if(hour===null) return;
                        let dom = prompt("DOM:", p[2]); if(dom===null) return;
                        let month = prompt("Month:", p[3]); if(month===null) return;
                        let dow = prompt("DOW:", p[4]); if(dow===null) return;
                        $.post("custom/update_announcement.php", {raw_line: c.raw, min, hour, dom, month, dow}, function(resp){
                            alert(resp); loadCronList();
                        });
                    });

                let delBtn = $("<button>").text("Delete")
                    .css({"background":"#dc3545", "color":"white"})
                    .click(function(){
                        if (!confirm("Delete " + c.file + "?")) return;
                        $.post("custom/delete_announcement.php", {raw_line: c.raw}, function(data){
                            alert(data); loadCronList();
                        });
                    });

                row.append($("<td>").append(toggleBtn));
                row.append($("<td>").append(playBtn).append(editBtn).append(delBtn));
                table.append(row);
            });
        });
    }
    loadCronList();
});
</script>
<style>
    .submit { padding:6px 12px; margin:4px; }
    
    /* Center all data in the cron table */
    #cron_table th, #cron_table td {
        border: 1px solid #666;
        padding: 8px;
        text-align: center !important;
        vertical-align: middle;
    }
    
    #cron_table tbody tr:nth-child(even) { 
        background-color: #f9f9f9; 
    }
    
    #cron_table tbody tr:hover { 
        background-color: #f0f8ff; 
    }
</style>
<?php } ?>
