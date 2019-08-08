resetMaxFile #noPrompt
SetQuietMode true
logsystem.logName "originalRender.log"
units.SystemType = #Meters

function main = (
    filesToRender = #(
        {scene_list}
    )

    for fi=1 to filesToRender.count do (
        scene_path = "{res_path}" + "\\" + filesToRender[fi]
        loadMaxFile scene_path useFileUnits:true quiet:true

        arnoldRenderer = Arnold()
        if classof renderers.current != classof arnoldRenderer do (
            renderers.current = arnoldRenderer
        )

        rendered_image_path = "{output_path}" + "\\Color\\" + maxFileName + ".jpg"

        rstart = timeStamp()
        render outputfile:rendered_image_path
        rend = timeStamp()
        relapsed = ((rend - rstart) / 1000.0)

        file_path = "{output_path}\\..\\" + maxFileName + ".or.render_time.log"
        a = (createFile file_path mode:"w")
        line = (relapsed as string)
        format "%" line to:a
    )
)

main()
resetMaxFile #noPrompt
quitMax #noPrompt
