import QtQuick 2.9
import Esri.ArcGISRuntime 100.14



Item {
    property var openHtmlTags:[]

    /**********This function modifies/adds certain tags in the input html to  make the images and the UI look better in RichText ****  */

    function getHtmlSupportedByRichText(inputString, imagewidth, defaultString){

        let tagText = ""
        let updatedHtml = ""
        let previoustag = ""

        let txt = inputString.replace("http://", "https://")

        for (var i = 0; i < txt.length; i++) {
            let nextChar = txt.charAt(i)

            switch(nextChar)
            {
                // if it is start of a tag the initialize a variable
            case "<":
                tagText = "<"
                break;
                //if it is end of the tag then process the whole tag and set the tag variable to empty
            case ">":
                tagText += ">"
                let modifiedTag = processHtmlTag(tagText,imagewidth,previoustag)
                previoustag = modifiedTag
                if(modifiedTag === "</div>")
                {
                    let opentag = openHtmlTags.pop()
                    if(opentag)
                        modifiedTag = opentag.replace("<","</")

                }
                else
                {
                    if(modifiedTag.includes("</"))
                        openHtmlTags.pop()
                }
                updatedHtml += modifiedTag


                tagText = ""

                break;
                //if it is within a tag then just append to the tag body. If it is outside of a tag
                // then if it is outside of href and is within a <td> then create a new <td>. This will resolve the issue
                // where the table cell is specified as display:table-cell and the text content is enclosed within a div
            default:
                if(tagText > "")
                    tagText += nextChar
                else
                {
                    if(nextChar > ""){
                        if((previoustag === "</a>") && openHtmlTags[openHtmlTags.length -1] === "<td>")
                        {
                            previoustag = "<td>"
                            updatedHtml += "</td><td>" + nextChar
                        }
                        else
                            updatedHtml += nextChar
                    }
                }

            }


        }

        return updatedHtml

    }

    function processHtmlTag(txt,imagewidth,previoustag)
    {
        let modifiedTag = ""
        if(txt.includes("style=")){

            //get the substring excluding '<' in the beginning and "'>" at the end
            //e.g. <div style='margin: 1em 0;'>
            let txtToSplit = txt.substr(1,txt.length-2)

            let csstags = txtToSplit.split(" ")
            let tag = csstags[0]
            //processing just the div tags for now
            if(tag === "div")
            {

                modifiedTag = processStyleOfDivTag(txtToSplit,txt)

            }
            else if(tag === "img")
            {

                modifiedTag = scrubImgStyle(txt,imagewidth,previoustag,true)

            }

            if(modifiedTag === ""){
                modifiedTag = txt

            }

        }
        else
        {
            let txtToSplit1 = txt.substr(1,txt.length-2)

            let csstags1 = txtToSplit1.split(" ")
            let tag1 = csstags1[0]

            if(tag1 === "img")
            {

                modifiedTag = scrubImgStyle(txt,imagewidth,previoustag,false)

            }

            else{
                //get the first html markup
                let starttag = ""
                let tagindex =   txt.indexOf(" ")
                if(tagindex > -1)
                {
                    let _tag = txt.substr(0,tagindex)
                    starttag = _tag + ">"
                }
                else
                {
                    starttag = txt

                }


                if(txt.substr(0,2) !== "</" && !txt.includes("/>") )
                    openHtmlTags.push(starttag)

                modifiedTag = txt
            }
        }

        return modifiedTag

    }

    function processStyleOfDivTag(enclosedText,inputString)
    {
        let modifiedTagAfterProcessingDiv = ""
        let tagdesc = enclosedText.substr(3,enclosedText.length -1)
        //" style='margin: 1em 0;'"
        //get the style
        if(tagdesc > "")
        {
            if(enclosedText.includes("style="))
            {
                let styleindx = enclosedText.indexOf("style=")
                let styleindxstart = enclosedText.indexOf("'")

                let styleindxend = enclosedText.indexOf("'", styleindxstart + 1)
                let no_of_chars = styleindxend - styleindxstart
                let stylestring = enclosedText.substr(styleindxstart + 1,no_of_chars - 1)
                //e.g. stylestring - "'margin: 1em 0;'"
                let stylesubsplits = stylestring.split(';')
                for(let k=0;k< stylesubsplits.length; k++)
                {
                    let _tagcss = stylesubsplits[k]
                    if(_tagcss > ""){
                        let tagcss = _tagcss.replace(" ","")
                        if(tagcss === "display:table")
                        {
                            modifiedTagAfterProcessingDiv = "<table>"
                            openHtmlTags.push(modifiedTagAfterProcessingDiv)
                        }
                        else if(tagcss === "display:table-cell")
                        {

                            modifiedTagAfterProcessingDiv = "<tr><td>"
                            openHtmlTags.push("<td>")
                        }
                        else if(tagcss === "display:table-row")
                        {
                            modifiedTagAfterProcessingDiv = "<tr>"
                            openHtmlTags.push(modifiedTagAfterProcessingDiv)
                        }
                        else
                        {
                            if(!modifiedTagAfterProcessingDiv.includes("<table>") && !modifiedTagAfterProcessingDiv.includes("<tr>") && !modifiedTagAfterProcessingDiv.includes("<td")){
                                let subtag = tagcss.split(':')
                                if(subtag[0] !== "box-sizing" && subtag[0] !== "border-radius" && subtag[0] !== "margin"){
                                    if(modifiedTagAfterProcessingDiv > "")
                                        modifiedTagAfterProcessingDiv += ";" + tagcss
                                    else
                                        modifiedTagAfterProcessingDiv = "<div style='"+ tagcss
                                }
                            }
                        }


                    }
                }
                if(modifiedTagAfterProcessingDiv.includes("style="))
                    modifiedTagAfterProcessingDiv +="'>"



            }
        }
        if(modifiedTagAfterProcessingDiv.substr(0,2) !== "</" && !inputString.includes("/>") )
        {
            if(modifiedTagAfterProcessingDiv.includes("<div"))

                openHtmlTags.push("<div>")

        }
        return modifiedTagAfterProcessingDiv


    }

    //construct the img tag
    function scrubImgStyle(txt,imagewidth,previoustag,asStyle)
    {
        let modifiedTag = txt[0] + "img "

        let regex = /width=(\s*)\d+/
        if(asStyle)
            regex = /width:(\s*)\d+/

        let srcexpr = txt.match(/src='(.*?)'/);
        if(srcexpr)
        {
            modifiedTag += srcexpr[0]
        }

        let widthexpr = txt.match(regex);
        if(widthexpr){
            let width = widthexpr[0].substr(6)
            if (parseInt(width) > imagewidth)
                width = imagewidth - app.units(40)

            modifiedTag += " width=" + width.toString()
        }
        else
        {
            //if a div tag then width must be present inside style
            let previousdivwidthexpr = previoustag.match(/width:(\s*)\d+/);
            if(previousdivwidthexpr)
            {
                let _width = previousdivwidthexpr[0].substr(6)
                if (parseInt(_width) > imagewidth)
                {
                    _width = imagewidth - app.units(40)
                    modifiedTag += " width=" + _width.toString()
                }
            }
            else
            {
                let newwidth = imagewidth - app.units(40)
                modifiedTag += " width=" + newwidth.toString()
            }
        }



        modifiedTag += " />"
        return modifiedTag

    }
     function getFieldLabelFromPopup(featureTable,field)
    {
        try{
            if(featureTable  && featureTable.popupDefinition)
            {
                let popupFields = featureTable.popupDefinition.fields
                for(let p=0; p<popupFields.length;p++)
                {
                    let _fld = popupFields[p]
                    if(_fld.fieldName === field && _fld.label > "")
                    {
                        field = _fld.label
                        return field
                    }
                }
            }
            if(featureTable && featureTable.fields)
            {
                let fields = featureTable.fields
                field = utilityFunctions.getFieldAlias(fields,field)
            }

            return field
        }
        catch(ex)
        {
            console.error("Error:",ex.toString())
            return field
        }
    }

     function getFieldAlias(fields,fieldName)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            var name = ""
            if(field.name)
                name = field.name
            else if(field.fieldName)
                name = field.fieldName


            if(name.toUpperCase() === fieldName.toUpperCase())
            {
                if(field.label)
                    return field.label
                else
                {
                    if(field.alias)
                        return field.alias
                }

            }
        }
        return fieldName
    }

    function getFieldType(fields,fieldName)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            var name = ""
            if(field.name)
                name = field.name
            else if(field.fieldName)
                name = field.fieldName


            if(name.toUpperCase() === fieldName.toUpperCase())
            {
                return field.fieldType

            }
        }
        return null
    }

     function getTimeDiff(date1)
    {
        let timeDiff =  ""

        let date_obj2 = new Date(date1)
        let date_obj1 = new Date()


        let diff_secs =(date_obj1.getTime() - date_obj2.getTime()) / 1000;
        if(diff_secs > 60)
        {
            let diff_mins = diff_secs/60;
            if(diff_mins > 60)
            {
                let diff_hrs = diff_mins/60;
                if(diff_hrs > 24)
                    timeDiff = getFormattedFieldValue(date1,Enums.FieldTypeDate)
                else
                {
                    let hrs = Math.round(diff_hrs)
                    if(hrs > 1)
                        timeDiff = strings.hours_ago.arg(hrs)
                    else
                        timeDiff = strings.hour_ago.arg(hrs)
                }
            }
            else
            {
                let mins = Math.round(diff_mins)
                if(mins > 1)
                    timeDiff = strings.minutes_ago.arg(mins)
                else
                    timeDiff = strings.minute_ago.arg(mins)

            }
        }
        else
        {
            let secs = Math.round(diff_secs)
            if (secs > 1)
                timeDiff = strings.seconds_ago.arg(secs)
            else
                timeDiff = strings.second_ago.arg(secs)

        }

        return timeDiff

    }

    function getFormattedFieldValue(_fieldVal,fieldType)
    {

        let isNotNumber = isNaN(_fieldVal)
        if(_fieldVal && !isNotNumber)
        {
            let formattedVal = _fieldVal.toLocaleString()
            if(formattedVal)
                _fieldVal = formattedVal
        }
        //check if it is a date
        if(fieldType === Enums.FieldTypeDate)
        {
            let dt = Date.parse(_fieldVal)
            if(dt)
            {
                let date_ob = new Date(dt)
                let _datepart = date_ob.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
                let timepart = date_ob.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)

                _fieldVal = _datepart + ", " + timepart


            }

        }
        return _fieldVal
    }

    function getCodedValue(fields,fieldName,fieldValue)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            if(field.name === fieldName)
            {
                var domain = field.domain
                if(domain && domain.codedValues)
                {
                    var codedValues = domain.codedValues

                    for(var x=0;x<codedValues.length;x++)
                    {
                        if(codedValues[x].code  ===  fieldValue)
                        {
                            var codedValueObj = codedValues[x]
                            return codedValueObj.name
                        }
                    }


                }
                else
                    return fieldValue

            }
        }
        return fieldValue
    }

     function isFieldVisible(fields,fieldName)
    {
        for(var k=0;k< fields.length; k++)
        {
            var field = fields[k]
            var name = ""
            if(field.name)
                name = field.name
            else if(field.fieldName)
                name = field.fieldName


            if(name.toUpperCase() === fieldName.toUpperCase())
            {
                if(field.visible)
                    return field.visible
                else
                    return true

            }
        }
        return true
    }






}
