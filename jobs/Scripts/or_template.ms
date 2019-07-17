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

        render outputfile:rendered_image_path
    )
)

main()
resetMaxFile #noPrompt
quitMax #noPrompt
