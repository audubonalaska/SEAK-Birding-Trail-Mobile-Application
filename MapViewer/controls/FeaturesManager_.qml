import QtQuick 2.9

import Esri.ArcGISRuntime 100.14
import ArcGIS.AppFramework 1.0

Item {

    property var _featuretypecodedValue : null
    property var subtype_info : ({})



    //*********************************** Features functions ********************************************//

    function getUniqueFieldName(_table)
    {
        if(_table){
            let fields = _table.fields
            for(let k=0;k<fields.length;k++)
            {
                let fldType = fields[k].fieldType
                if(fldType === Enums.FieldTypeOID)
                    return fields[k].name
            }
        }
        return null

    }

    function doesInclude(fields,key)
    {
        for(var k=0;k<fields.length;k++)
        {
            let field = fields[k]
            if(field.fieldName.toUpperCase() === key.toUpperCase())
                return true
        }
        return false
    }

    function scrubHtml(_txt,imagewidth, defaultString) {
        let txt = _txt.replace("http://", "https://")

        txt = txt.trim();
        let newtxt = txt

        let outTxt = "";
        let arr = txt.split("<img");

        for (var i = 0; i < arr.length; i++) {
            if (i === 0) {
                outTxt += arr[i];
                continue;
            }
            //outTxt += ("<img" + arr[i]).replace(/(<img.+src=')(?!http|ftp)(.*?)'/, "$1" + app.portal.url + "/home/" + "$2'");
            outTxt += ("<img" + arr[i])
            let newwidth = imagewidth - app.units(40)
            let newstr = "<img width=" + newwidth.toString()
            newtxt = outTxt.replace("<img",newstr)

        }

        return newtxt
    }

    function checkEditPermissions(identifiedFeature,portalItem,_portal)
    {
        let isEditable = false
        let hasEditRole = false
        let isFeatureTableEditable = false
        if(app.isSignedIn)
        {

            let _portalInfo = _portal.portalInfo

            //Check if the featureTable is editable
            // let identifiedFeature = mapView.identifyProperties.features[currentPageNumber-1]
            if(identifiedFeature)
            {
                let _featureTable = identifiedFeature.featureTable
                if(_featureTable.editable && _featureTable.featureTableType === Enums.FeatureTableTypeServiceFeatureTable)
                {
                    //check ownership-based access
                    if(_featureTable.canUpdate(identifiedFeature))
                        isFeatureTableEditable = _featureTable.editable

                }
            }

            if(isFeatureTableEditable)
            {

                //check if the user has the edit privilege
                if(_portal.portalUser && !userHasEditRole)
                {
                    for(var i=0;i<_portal.portalUser.privileges.count;i++)
                    {
                        let type = _portal.portalUser.privileges.get(i).type
                        if(type === 0){
                            hasEditRole = true
                            userHasEditRole = true
                            break;
                        }
                    }
                }
                if(userHasEditRole)
                {
                    //for lite license get the userType
                    if (ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelLite)
                    {

                        //  let licenseInfo = _portalInfo.licenseInfo
                        //  let licenseResult = ArcGISRuntimeEnvironment.setLicense(licenseInfo)
                        _portal.fetchLicenseInfoStatusChanged.connect(()=>{
                                                                          if (_portal.fetchLicenseInfoStatus === Enums.TaskStatusCompleted) {
                                                                              const licenseInfo = _portal.fetchLicenseInfoResult;

                                                                              let licenseResult = ArcGISRuntimeEnvironment.setLicense(licenseInfo)
                                                                          }
                                                                      });
                        _portal.fetchLicenseInfo();

                    }


                    //check license
                    if ((ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelBasic) ||
                            (ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelStandard) ||
                            (ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelDeveloper)
                            ||(ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelAdvanced)) {
                        if(isFeatureTableEditable)
                            isEditable = true


                    }
                }
                else
                {
                    if(portalItem.access === "public")
                        isEditable = true
                    else
                        isEditable = false
                }

            }
            else
                isEditable = false

        }
        return isEditable
    }


    function getFieldValueFromModel(feature,fieldname,editedmodel)
    {

        let fieldVal
        for(let k=0;k<editedmodel.count;k++)
        {
            let fldObj = editedmodel.get(k)
            if(fldObj.label === fieldname)
            {
                if(fldObj.editedValue !== fldObj.fieldValue)
                {
                    if(fldObj.domainName && (fldObj.domainName.count > 0 || fldObj.domainName.length > 0))
                    {
                        if(fldObj.domainName.length)
                        {
                            if(fldObj.domainName.length > 0)
                            {
                                for(let i=0;i<fldObj.domainName.length;i++)
                                {

                                    if(fldObj.domainName[i] === fldObj.fieldValue)
                                        return fldObj.domainCode[i]
                                }
                            }
                        }
                        else
                        {
                            if(fldObj.domainName.count)
                            {
                                if(fldObj.domainName.count > 0)
                                {
                                    for(let p=0;p<fldObj.domainName.count;p++)
                                    {
                                        let domainfld = fldObj.domainName.get(p)
                                        if(domainfld.name === fldObj.fieldValue)
                                            return fldObj.domainCode.get(p).code
                                    }
                                }
                            }


                        }

                    }

                    else if(fldObj.fieldType === Enums.FieldTypeDate)
                    {
                        fieldVal = new Date(fldObj.fieldValue)//new Date(new Date(fldObj.fieldValue) - new Date().getTimezoneOffset() * 60000)

                        return fieldVal
                    }
                    else
                        return fldObj.fieldValue
                }
                else
                    return null


            }


        }

    }

    function getOldFieldValueFromModel(feature,fieldname,editedmodel)
    {
        for(let k=0;k<editedmodel.count;k++)
        {
            let fldObj = editedmodel.get(k)
            if(fldObj.label === fieldname)
                return fldObj.editedValue


        }

    }

    // get the value for field based on the prototype attributes defined in the template
    //for the corresponding subtype
    function getFieldValueFromTemplate(_featureTable,featureTypeFieldValue,field)
    {
        let featuretype = _featureTable.typeIdField
        let codedValues = []
        let nameValues = []
        let _fieldVal = null
        let minValue=0
        let maxValue = 0
        let _fieldValcode = null
        let targetFieldName = field.name
        if(featuretype && subtype_info.subtype_templates)
        {
            //need to get the code from name

            //get the fieldvalue from subtype templates if available

            let fieldTemplate = subtype_info.subtype_templates[featureTypeFieldValue]

            if(fieldTemplate)
                _fieldValcode = fieldTemplate[targetFieldName]

        }

        if(!_fieldValcode || !_fieldValcode.trim() > "")
        {
            if (!field.nullable && subtype_info.subtype_domain)
            {
                //need to get the code from name

                let fielddomains = subtype_info.subtype_domain[featureTypeFieldValue]
                if(fielddomains){
                    let _domain = fielddomains[targetFieldName]
                    if(_domain && _domain.codedValues)
                    {
                        let codedValueObj = _domain.codedValues[0]
                        _fieldValcode = codedValueObj.code
                    }
                }


            }
        }


        return _fieldValcode

    }



    function getPopupFieldValue(popupManager,fieldName)
    {

        let _popupfield = popupManager.fieldByName(fieldName)
        // To force it to use 2 decimal places instead of reading from webmap uncomment the lines below
        /*let popupFieldFormat = ArcGISRuntimeEnvironment.createObject("PopupFieldFormat")
        popupFieldFormat.useThousandsSeparator = true;

        // If the popupFieldValue's fieldType is Float/ Double - round it down to 2 decimal places
        if ( popupManager.fieldType(_popupfield) === Enums.FieldTypeFloat32 || popupManager.fieldType(_popupfield) === Enums.FieldTypeFloat64 ){
            popupFieldFormat.decimalPlaces = 2;
        }

        _popupfield.format = popupFieldFormat*/
        let fieldVal = popupManager.fieldValue(_popupfield) !== null ? popupManager.formattedValue(_popupfield) : null
        return fieldVal
    }

    function populateModel(feature1,visiblefields,popupManager,attrListModel)
    {

        attrListModel.clear()
        let popupModel = popupManager.displayedFields
        if (popupModel.count) {

            //var feature1 = mapView.identifyProperties.features[mapView.identifyProperties.currentFeatureIndex]//mapView.identifyProperties.features[currentPageNumber-1]
            //var visiblefields = mapView.identifyProperties.fields[mapView.identifyProperties.currentFeatureIndex]//mapView.identifyProperties.fields[currentPageNumber-1]
            var attributeJson1 = feature1.attributes.attributesJson
            //attrListModel.clear()
            var _featuretable  = feature1.featureTable
            var fields = _featuretable.fields

            for(var key in visiblefields)
            {
                var field = visiblefields[key]
                var fldname = ""
                if(field.name)
                    fldname = field.name
                else
                    fldname = field.fieldName

                //check if it is an expression
                //if it is an expression then get it from popupManager
                var popupfieldVal = ""
                var exprfld = fldname.split('/')
                if(exprfld.length > 1)
                {
                    var expr =exprfld[1]
                    var exprResults = popupManager.evaluateExpressionsResults
                    for(var k = 0;k<popupManager.evaluateExpressionsResults.length;k++)
                    {
                        var exprobj = popupManager.evaluateExpressionsResults[k].popupExpression
                        if(exprobj.name === expr)
                        {
                            var val = popupManager.evaluateExpressionsResults[k].result

                            var _type = exprobj.returnType

                            if(_type === Enums.PopupExpressionReturnTypeNumber)
                                popupfieldVal = app.getFormattedFieldValue(val,field.fieldType)
                            else
                                popupfieldVal = val
                            fldname = exprobj.title
                            break;
                        }
                    }
                }

                //get the fieldValue from PopupManager if not populated
                if(!popupfieldVal)
                    popupfieldVal = getPopupFieldValue(popupManager,fldname)


                var _fieldVal = popupfieldVal
                //if not populated get it from attribute Json

                if(!_fieldVal)
                {


                    //var fieldValAttrJson = app.getCodedValue(fields,fldname,attributeJson1[fldname])
                    // _fieldVal = getFormattedFieldValue(fieldValAttrJson)
                    var fieldValAttrJson = app.getCodedValue(fields,fldname,attributeJson1[fldname])
                    var fldType =   field.fieldType//app.getFieldType(fields,key)
                    _fieldVal = app.getFormattedFieldValue(fieldValAttrJson,fldType)

                }

                var _fieldAlias = fldname
                var _fieldType = -1

                if(field.label)
                    _fieldAlias = field.label
                else if(field.alias)
                    _fieldAlias = field.alias
                if(field.type)
                    _fieldType = field.type

                var length = 0

                for(var k1 = 0;k1<fields.length;k1 ++)
                {
                    var fld = fields[k1]
                    if(fld.name === field.fieldName)
                        length = fld.length
                }

                // const fld = fields.filter(_fld => _fld.name === field.fieldName);



                attrListModel.append({
                                         "description":"",
                                         "label": _fieldAlias,
                                         "fieldValue": _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                         "fieldType":_fieldType,//field.type?field.type:Enums.FieldTypeText,
                                         "editedValue":_fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                         "isEditable":field.editable,
                                         "length":length,//field.length,
                                         "canShowEditIcon":false,
                                         "canShowCalendarIcon":false,
                                         "canShowDomainIcon":false


                                     })


            }

            //return popupManager.displayedFields
        } else {
            // This case handles map notes
            // var feature = mapView.identifyProperties.features[currentPageNumber-1]
            let attributeJson = feature1.attributes.attributesJson
            attrListModel.clear()
            if (attributeJson.hasOwnProperty("TITLE")) {
                if (attributeJson["TITLE"]) {
                    attrListModel.append({
                                             "label": "TITLE", //qsTr("Title"),
                                             "fieldValue": attributeJson["TITLE"].toString()
                                         })
                }
            }
            if (attributeJson.hasOwnProperty("DESCRIPTION")) {
                if (attributeJson["DESCRIPTION"]) {
                    attrListModel.append({
                                             "label": "DESCRIPTION", //qsTr("Description"),
                                             "fieldValue": attributeJson["DESCRIPTION"].toString()
                                         })
                }
            }
            if (attributeJson.hasOwnProperty("IMAGE_LINK_URL")) {
                if (attributeJson["IMAGE_LINK_URL"]) {
                    attrListModel.append({
                                             "label": "IMAGE_LINK_URL",
                                             "fieldValue": attributeJson["IMAGE_LINK_URL"].toString()
                                         })
                }
            }

        }

    }



    function populateModelForEditAttributes(feature1,attrListModel,popupManager)
    {
        attrListModel.clear()
        subtype_info = {}
        _featuretypecodedValue = null

        let subtypeField = feature1.featureTable.typeIdField
        let attributeJson1 = feature1.attributes.attributesJson

        let subtype_domain = []
        if(subtypeField)
        {
            let subtypeFieldValue = attributeJson1[subtypeField.toLowerCase()]
            if(!subtypeFieldValue)
                subtypeFieldValue = attributeJson1[subtypeField]
            //subtype_domain = populateSubTypeDomains(feature1,subtypeFieldValue)
            _featuretypecodedValue =  app.getDomainCodeFromFeatureTable(feature1.featureTable,subtypeField,subtypeFieldValue)//mapViewerCore.getDomainCode(sketchEditorManager.currentLayerId,subtypeField,subtypeFieldValue)
            subtype_info = populateSubTypeDomainsFromFeatureTable(feature1.featureTable,_featuretypecodedValue)

        }


        let _featuretable  = feature1.featureTable
        let fields = _featuretable.fields

        for(var key in fields)

        {
            let field = fields[key]
            if(field)
            {
                let fldname = ""
                if(field.name)
                    fldname = field.name
                else
                    fldname = field.fieldName

                //check if it is an expression
                //if it is an expression then get it from popupManager
                let popupfieldVal = ""
                let exprfld = fldname.split('/')

                //get the fieldValue from PopupManager if not populated
                //need to check if edit is disabled in popup
                let isEditEnabledInPopup = isFieldEditable(popupManager,fldname)
                if(!(exprfld.length > 1) && field.editable && isEditEnabledInPopup)
                {
                    popupfieldVal = getPopupFieldValue(popupManager,fldname)
                    let _fieldVal = popupfieldVal
                    //if not populated get it from attribute Json

                    if(!_fieldVal){
                        let fieldValAttrJson = app.getCodedValue(fields,fldname,attributeJson1[fldname])
                        let fldType =   field.fieldType//app.getFieldType(fields,key)
                        _fieldVal = app.getFormattedFieldValue(fieldValAttrJson,fldType)
                    }
                    let _fieldAlias = fldname

                    if(field.label)
                        _fieldAlias = field.label
                    else if(field.alias)
                        _fieldAlias = field.alias

                    //get the domains if it has a domain
                    let _codedValues = []//field.domain
                    let _nameValues = []
                    let minValue=0
                    let maxValue = 0

                    //check if the field is a subtype field

                    if(subtypeField && subtypeField.toUpperCase() === fldname.toUpperCase())
                    {
                        let codedValues_subtypes = getSubtypesFromFeatureTable(feature1.featureTable)

                        codedValues_subtypes.forEach(element => {
                                                         _codedValues.push({"code":element.code.toString()})
                                                         _nameValues.push({"name":element.name})
                                                     }
                                                     )

                    }
                    else
                    {
                        if(field.domain)
                        {
                            //check if it is a range domain

                            if(field.domain.domainType === Enums.DomainTypeRangeDomain)
                            {
                                minValue = field.domain.minValue
                                maxValue = field.domain.maxValue
                            }
                            else
                            {
                                let domainObj = field.domain.codedValues
                                if(domainObj){
                                    if(domainObj.length > 0)
                                    {
                                        if(field.nullable)
                                        {
                                            if(typeof domainObj[0].code  === "number")
                                                _codedValues.push({"code":"-999"})
                                            else
                                                _codedValues.push({"code":"None"})

                                            _nameValues.push({"name":"None"})
                                        }
                                    }

                                    for(var k=0;k<domainObj.length;k++)
                                    {

                                        _codedValues.push({"code":domainObj[k].code.toString()})
                                        _nameValues.push({"name":domainObj[k].name})
                                    }
                                }

                            }

                        }
                        else
                        {
                            if(subtypeField && subtype_info.subtype_domain)
                            {

                                let fielddomains = subtype_info.subtype_domain[_featuretypecodedValue]
                                if(fielddomains)
                                {
                                    let coded_name_ValuesObj =  populateCodedValuesWithDomainObject(fielddomains,_codedValues,_nameValues,field.name)
                                    //console.log("codedvalues")

                                    _codedValues = coded_name_ValuesObj.codedValues

                                    _nameValues = coded_name_ValuesObj.nameValues

                                }
                            }

                        }

                    }
                    let length = 0

                    for(var k1 = 0;k1<fields.length;k1 ++)
                    {
                        let fld = fields[k1]
                        if(fld.name === field.fieldName)
                            length = fld.length
                    }


                    //if not check if is a domain field. domain can be at the field level or featuretypes level

                    attrListModel.append({
                                             "description":"",
                                             "fieldName":fldname,
                                             "label": _fieldAlias,
                                             "fieldValue": _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                             "fieldType":field.fieldType,
                                             "editedValue":_fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                             "isEditable":field.editable,
                                             "unformattedValue":attributeJson1[fldname] !== null?attributeJson1[fldname].toString():"",
                                             "length":length,//field.length,
                                             "domainName":_nameValues,
                                             "domainCode":_codedValues,
                                             "nullableValue":field.nullable,
                                             "minValue":minValue,
                                             "maxValue":maxValue,
                                             "canShowEditIcon":_nameValues.length === 0 && field.fieldType !== Enums.FieldTypeDate,
                                             "canShowCalendarIcon":field.fieldType === Enums.FieldTypeDate,
                                             "canShowDomainIcon":_nameValues.length > 0

                                         })
                }

            }
        }


    }


    //1. get the typeId field

    //2.Check if it has featureTypes. If yes then need to load the field domains dynamically
    //for each typeId . domain can be defined in field or inside featureTypes
    //domainType: 0 - codedvalue, 1- inherited , 2 - range

    function isLegendBasedOnFeatureType(_featureTable)
    {
        //check if the legend is based on typeid field
        //
        let renderer = _featureTable.layer.renderer
        let featuretype = _featureTable.typeIdField
        let isBasedOnSubtypeField = true
        if(renderer && renderer.fieldNames && renderer.fieldNames.length > 0)
        {
            var rendererfield = renderer.fieldNames[0]
            if(rendererfield !== featuretype )
                isBasedOnSubtypeField = false
        }
        return isBasedOnSubtypeField
    }

    function populateCodedValuesForFeatureType(_featureTable,field,codedValues,nameValues)
    {
        let codedValues_subtypes = getSubtypesFromFeatureTable(_featureTable)

        codedValues_subtypes.forEach(element => {
                                         codedValues.push({"code":element.code.toString()})
                                         nameValues.push({"name":element.name})
                                     }
                                     )
    }

    function populatedCodedValuesForFieldDomain(codedValues,nameValues,field)
    {
        let domainObj = field.domain.codedValues
        if(domainObj){
            if(domainObj.length > 0)
            {
                if(field.nullable)
                {
                    if(typeof domainObj[0].code  === "number")
                        codedValues.push({"code":"-999"})
                    else
                        codedValues.push({"code":"None"})

                    nameValues.push({"name":"None"})
                }


            }

            for(var k=0;k<domainObj.length;k++)
            {

                codedValues.push({"code":domainObj[k].code.toString()})
                nameValues.push({"name":domainObj[k].name})
            }
        }
    }

    function populateCodedValuesWithDomainObject(fielddomains,codedValues,nameValues,fieldName)
    {
        if(fielddomains)
        {

            let domain = fielddomains[fieldName]
            if(domain){

                let domainValues = domain.codedValues
                if(domainValues)
                {
                    for(var k1=0;k1 < domainValues.length;k1++){
                        let subtype = domainValues[k1]
                        {

                            nameValues.push({"name":subtype.name})
                            codedValues.push({"code":subtype.code.toString()})
                        }
                    }
                }
            }
        }
        return {codedValues,nameValues}
    }


    function updateFieldDomain(_featureTable,featureTypeFieldValue,targetFieldName)
    {
        let featuretype = _featureTable.typeIdField
        let codedValues = []
        let nameValues = []
        let _fieldVal = null
        let minValue=0
        let maxValue = 0
        if(featuretype && subtype_info.subtype_domain)
        {
            //need to get the code from name
            let _featuretypecodedValue =  mapViewerCore.getDomainCode(sketchEditorManager.currentLayerId,featuretype,featureTypeFieldValue)

            let fielddomains = subtype_info.subtype_domain[_featuretypecodedValue]
            if(fielddomains)
            {
                populateCodedValuesWithDomainObject(fielddomains,codedValues,nameValues,targetFieldName)

            }
            //get the fieldvalue from subtype templates if available
            if(subtype_info.subtype_templates)
            {


                let fieldTemplate = subtype_info.subtype_templates[_featuretypecodedValue]

                if(fieldTemplate){

                    let _fieldValcode = fieldTemplate[targetFieldName]

                    //let field_domains = subtype_info.subtype_domain[_featuretypecodedValue]
                    let _domain = fielddomains[targetFieldName]
                    if(_domain && _domain.codedValues)
                    {
                        for(var x=0;x<_domain.codedValues.length;x++)
                        {
                            if(_domain.codedValues[x].code  ===  _fieldValcode)
                            {
                                let codedValueObj = codedValues[x]
                                _fieldVal = codedValueObj.name
                            }
                        }
                        if(!_fieldVal && _domain)
                            _fieldVal = _domain.codedValues[0].name
                    }

                }
            }

        }


        return {codedValues, nameValues,_fieldVal}


    }



    function populateSubTypeDomainsFromFeatureTable(featureTable,subTypeCodedValue)
    {
        let subtype_domain = {}
        let subtype_templates = {}


        let subtypes = featureTable.featureTypes


        for(var k=0;k<subtypes.length;k++){
            let subtype = subtypes[k]
            subtype_domain[subtype.typeId] = subtype.domains  //[<fieldname>,<domain>]
            if(subtype.templates && subtype.templates.length > 0)
                subtype_templates[subtype.typeId] = subtype.templates[0].prototypeAttributes


        }
        return {subtype_domain,subtype_templates}


    }

    function getSubtypesFromFeatureTable(featureTable)
    {
        let subtypeNames = []
        let subtypes = featureTable.featureSubtypes
        if(subtypes.length === 0)
            subtypes = featureTable.featureTypes
        for(var k=0;k<subtypes.length;k++){
            let subtype = subtypes[k]
            let _templates = subtype.templates

            if(_templates.length)
            {
                let _name = _templates[0].name
                if(featureTable.featureTypes)
                    subtypeNames.push({"name":_name,"code":subtype.typeId})
                else
                    subtypeNames.push({"name":_name,"code":subtype.code})
            }
            else
            {

                if(featureTable.featureTypes)
                    subtypeNames.push({"name":subtype.name,"code":subtype.typeId})
                else
                    subtypeNames.push({"name":subtype.name,"code":subtype.code})
            }

        }
        return subtypeNames

    }



    //********************************** related Features functions **************************************//

    function getFeatureList(relatedFeatures,relatedFeaturesModel,featureListModel,relatedattrListModel)
    {
        relatedFeaturesModel.clear()

        let sortedFeatures =   getSortedRelatedFeatures(relatedFeatures,featureListModel)
        if(app.isInEditMode){
            populateEditableRelatedFeaturesWithFeatureCountOne(sortedFeatures,relatedattrListModel,relatedFeatures)
        }
        sortedFeatures.forEach(function(obj){

            relatedFeaturesModel.append((obj))
        }
        )

    }

    function populateEditableRelatedFeaturesWithFeatureCountOne(sortedFeatures,relatedattrListModel,relatedFeatures)
    {
        sortedFeatures.forEach(function(obj){
            if(obj.features.count === 1){
                let _feature = populateModelForRelatedEditAttributes(obj.serviceLayerName,obj.features.get(0).objectid,relatedattrListModel,relatedFeatures)
                _feature.editFields = relatedattrListModel
                obj.editableFeature = _feature

            }

        })
    }

    function bindRelatedFeaturesModel (relatedFeatures,relatedFeaturesModel,featureListModel,relatedattrListModel) {

        getFeatureList(relatedFeatures,relatedFeaturesModel,featureListModel,relatedattrListModel)

    }

    function getSortedRelatedFeatures(relatedFeaturesList,featureListModel)
    {
        let relatedFeatures = []

        if(relatedFeaturesList)
        {
            relatedFeaturesList.forEach(function(featureObj){
                let fclass = featureObj["serviceLayerName"]
                let displayField = featureObj["displayFieldName"]


                let fclassObject =  relatedFeatures.filter(function(featObj) {
                    return featObj.serviceLayerName === fclass;
                });
                if(fclassObject && fclassObject.length > 0)
                {
                    relatedFeatures.map(function(featObj) {
                        if (featObj["serviceLayerName"] === fclass)
                        {
                            let isPresent = false

                            if(!isPresent)
                            {
                                let feat = {}
                                feat["displayFieldName"] = displayField
                                feat["serviceLayerName"] = fclass
                                let fields = []

                                let _attributes = featureObj["feature"].attributes.attributeNames

                                if(featureObj["feature"].featureTable){
                                    let _fields = featureObj["feature"].featureTable.fields

                                    let feature1 = featureObj["feature"]
                                    let editorInfo = app.getEditorTrackingInfo(feature1)
                                    if(editorInfo){
                                        feat.isEditorTrackingEnabled = true
                                        feat.editorInfo = editorInfo
                                    }
                                    else
                                    {
                                        feat.isEditorTrackingEnabled = false
                                    }

                                    for(var k = 0;k<_fields.length;k++){

                                        var _field = {}
                                        var fld = _fields[k]
                                        let _value  = featureObj["feature"].attributes.attributeValue(fld.name)
                                        _field.FieldName = fld.name
                                        if(_value)
                                        {

                                            var fieldValAttrJson = app.getCodedValue(_fields,fld.name,_value)
                                            var fldType =   fld.fieldType
                                            var _fieldVal = app.getFormattedFieldValue(fieldValAttrJson,fldType)

                                            if(_fieldVal)
                                                _field.FieldValue = _fieldVal.toString()
                                            else
                                                _field.FieldValue = "null"

                                        }
                                        else
                                            _field.FieldValue = "null"
                                        fields.push(_field)


                                    }

                                    feat.fields = fields

                                    if(featureObj["geometry"])
                                        feat["geometry"] = featureObj["geometry"]
                                    else
                                        feat["geometry"] = ""

                                    let objectid_fldname = getUniqueFieldName(featureObj["feature"].featureTable)

                                    feat["objectid"] = featureObj["feature"].attributes.attributeValue(objectid_fldname)
                                    //feat["objectid"] = featureObj["feature"].attributes.attributeValue("OBJECTID")


                                    featObj.features.append(feat)
                                }

                            }
                        }
                    })
                }
                else
                {
                    fclassObject = {}
                    fclassObject["serviceLayerName"] = fclass
                    fclassObject["showInView"] = false

                    fclassObject.features =  featureListModel.createObject(parent);
                    let feat = {}

                    let fields = []

                    let _attributes = featureObj["feature"].attributes.attributeNames
                    if(featureObj["feature"].featureTable){
                        let _fields = featureObj["feature"].featureTable.fields

                        for(var k = 0;k<_fields.length;k++){
                            var fld = _fields[k]

                            var _field = {}
                            let _value  = featureObj["feature"].attributes.attributeValue(fld.name)
                            _field.FieldName = fld.name


                            var fieldValAttrJson = app.getCodedValue(_fields,fld.name,_value)
                            var fldType =   fld.fieldType//app.getFieldType(fields,key)
                            var _fieldVal = app.getFormattedFieldValue(fieldValAttrJson,fldType)

                            if(_fieldVal)
                                _field.FieldValue = _fieldVal.toString()
                            else
                                _field.FieldValue = "null"

                            fields.push(_field)


                        }

                        feat.fields = fields

                        feat["displayFieldName"] = displayField
                        feat["serviceLayerName"] = fclass
                        if(featureObj["geometry"])
                            feat["geometry"] = featureObj["geometry"]
                        else
                            feat["geometry"] = ""

                        let objectid_fldname = getUniqueFieldName(featureObj["feature"].featureTable)
                        feat["objectid"] = featureObj["feature"].attributes.attributeValue(objectid_fldname)
                        //feat["objectid"] = featureObj["feature"].attributes.attributeValue("OBJECTID")

                        //get the editor date
                        var attributesJson = featureObj["feature"].attributes.attributesJson
                        var editDate = featureObj["feature"].attributes.attributesJson["EditDate"]
                        var editor = featureObj["feature"].attributes.attributesJson["Editor"]

                        var editedDate = app.getTimeDiff(editDate)

                        let feature1 = featureObj["feature"]
                        let editorInfo = app.getEditorTrackingInfo(feature1)
                        if(editorInfo){
                            feat.isEditorTrackingEnabled = true
                            feat.editorInfo = editorInfo
                        }
                        else
                        {
                            feat.isEditorTrackingEnabled = false
                        }
                        fclassObject.features.append(feat)
                        relatedFeatures.push(fclassObject)
                    }

                }
            }
            )
        }


        return relatedFeatures
    }


    function getSortedRelatedFeatures_(relatedFeaturesList)
    {
        let relatedFeatures = []
        if(relatedFeaturesList)
        {
            relatedFeaturesList.forEach(function(featureObj){
                let fclass = featureObj["serviceLayerName"]
                let displayField = featureObj["displayFieldName"]


                var fclassObject =  relatedFeatures.filter(function(featObj) {
                    return featObj.serviceLayerName === fclass;
                });
                if(fclassObject && fclassObject.length > 0)
                {
                    relatedFeatures.map(function(featObj) {
                        if (featObj["serviceLayerName"] === fclass)
                        {
                            var isPresent = false

                            if(!isPresent)
                            {
                                let feat = {}
                                feat["displayFieldName"] = displayField
                                feat["serviceLayerName"] = fclass
                                feat.fields = featureObj["fields"]
                                if(featureObj["geometry"])
                                    feat["geometry"] = featureObj["geometry"]
                                else
                                    feat["geometry"] = ""

                                let objectid_fldname = getUniqueFieldName(featureObj["feature"].featureTable)
                                feat["objectid"] = featureObj["feature"].attributes.attributeValue(objectid_fldname)
                                //feat["objectid"] = featureObj["feature"].attributes.attributeValue("OBJECTID")


                                featObj.features.append(feat)

                            }
                        }
                    })
                }
                else
                {
                    fclassObject = {}
                    fclassObject["serviceLayerName"] = fclass
                    fclassObject["showInView"] = false

                    fclassObject.features =  featureListModel.createObject(parent);
                    let feat = {}
                    feat.fields = featureObj["fields"]
                    feat["displayFieldName"] = displayField
                    feat["serviceLayerName"] = fclass
                    if(featureObj["geometry"])
                        feat["geometry"] = featureObj["geometry"]
                    else
                        feat["geometry"] = ""

                    let objectid_fldname = getUniqueFieldName(featureObj["feature"].featureTable)
                    feat["objectid"] = featureObj["feature"].attributes.attributeValue(objectid_fldname)
                    //feat["objectid"] = featureObj["feature"].attributes.attributeValue("OBJECTID")


                    fclassObject.features.append(feat)
                    relatedFeatures.push(fclassObject)

                }
            }
            )
        }
        return relatedFeatures
    }



    function populateModelForRelatedEditAttributes(featclass,objectid,relatedattrListModel,relatedFeatures)
    {
        relatedattrListModel.clear()
        let feature1 =  null

        var features =  relatedFeatures.filter(function(featObj) {
            return featObj.serviceLayerName === featclass;
        });

        if(features && features.length > 0)
        {
            let _featureObj =  features.filter(function(featureObj) {

                let objectid_fldname = getUniqueFieldName(featureObj["feature"].featureTable)
                let obj_id = featureObj["feature"].attributes.attributeValue(objectid_fldname)
                return obj_id === objectid;
                // return featureObj.feature.attributes.attributeValue("OBJECTID") === objectid;

            });
            feature1 = _featureObj[0].feature
            let subtypeField = feature1.featureTable.subtypeField

            let attributeJson1 = feature1.attributes.attributesJson

            let subtype_domain = []
            if(subtypeField)
            {
                let subtypeFieldValue = attributeJson1[subtypeField.toLowerCase()]
                if(!subtypeFieldValue)
                    subtypeFieldValue = attributeJson1[subtypeField]
                subtype_domain = populateSubTypeDomainsFromFeatureTable(feature1.featureTable,subtypeFieldValue)//populateSubTypeDomains(feature1,subtypeFieldValue)
            }


            let _featuretable  = feature1.featureTable
            let fields = _featuretable.fields
            let noneditableFieldTypes = [3,8,9]
            for(var key in fields)
            {
                let field = fields[key]
                if(field && field.editable && noneditableFieldTypes.indexOf(field.fieldType) < 0 )
                {
                    let fldname = ""
                    if(field.name)
                        fldname = field.name
                    else
                        fldname = field.fieldName

                    //check if it is an expression
                    //if it is an expression then get it from popupManager
                    var popupfieldVal = ""
                    var exprfld = fldname.split('/')

                    //get the fieldValue from PopupManager if not populated
                    //need to check if edit is disabled in popup
                    //let isEditEnabledInPopup = isFieldEditable(popupManager,fldname)
                    if(!(exprfld.length > 1) && field.editable)
                    {

                        let fieldValAttrJson = app.getCodedValue(fields,fldname,attributeJson1[fldname])
                        let fldType =   field.fieldType//app.getFieldType(fields,key)
                        let _fieldVal = app.getFormattedFieldValue(fieldValAttrJson,fldType)

                        let _fieldAlias = fldname

                        if(field.label)
                            _fieldAlias = field.label
                        else if(field.alias)
                            _fieldAlias = field.alias

                        //get the domains if it has a domain
                        let codedValues = []//field.domain
                        let nameValues = []
                        let minValue=0
                        let maxValue = 0

                        //check if the field is a subtype field
                        // var subtypeField = feature1.featureTable.subtypeField
                        if(subtypeField && subtypeField.toUpperCase() === fldname.toUpperCase())
                        {
                            let codedValues_subtypes = getSubtypesFromFeatureTable(feature1.featureTable)//getSubtypes(feature1) //populateSubTypeDomains(feature1)
                            if(codedValues_subtypes.length > 0)
                            {
                                if(field.nullable)
                                {
                                    codedValues.push({"code":"None"})
                                    nameValues.push({"name":"None"})
                                }
                            }
                            codedValues_subtypes.forEach(element => {
                                                             codedValues.push({"code":element.code})
                                                             nameValues.push({"name":element.name})
                                                         }
                                                         )

                        }
                        else
                        {
                            if(field.domain)
                            {
                                //check if it is a range domain

                                if(field.domain.domainType === Enums.DomainTypeRangeDomain)
                                {
                                    minValue = field.domain.minValue
                                    maxValue = field.domain.maxValue
                                }
                                else
                                {
                                    let domainObj = field.domain.codedValues
                                    if(domainObj){
                                        if(domainObj.length > 0)
                                        {
                                            if(field.nullable)
                                            {
                                                codedValues.push({"code":"None"})
                                                nameValues.push({"name":"None"})
                                            }
                                        }

                                        for(var k=0;k<domainObj.length;k++)
                                        {

                                            codedValues.push({"code":domainObj[k].code})
                                            nameValues.push({"name":domainObj[k].name})
                                        }
                                    }

                                }

                            }
                            else
                            {
                                let domain = subtype_domain[field.name]
                                if(domain)
                                {
                                    codedValues = []
                                    nameValues = []

                                    let domainValues = domain.codedValues
                                    for(var k=0;k < domainValues.length;k++){
                                        let subtype = domainValues[k]
                                        {

                                            nameValues.push({"name":subtype.name})
                                            codedValues.push({"code":subtype.code})
                                        }
                                    }
                                }

                            }

                        }

                        let length = 0

                        for(var k1 = 0;k1<fields.length;k1 ++)
                        {
                            let fld = fields[k1]
                            if(fld.name === field.fieldName || fld.name === field.name)
                                length = fld.length
                        }


                        //if not check if is a domain field. domain can be at the field level or featuretypes level

                        relatedattrListModel.append({
                                                        "description":"",
                                                        "FieldName":fldname,
                                                        "label": _fieldAlias,
                                                        "FieldValue": _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                                        "fieldType":field.fieldType,
                                                        "editedValue":_fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                                        "isEditable":field.editable,
                                                        "unformattedValue":attributeJson1[fldname] !== null?attributeJson1[fldname].toString():"",
                                                        "length":length,//field.length,
                                                        "domainName":nameValues,
                                                        "domainCode":codedValues,
                                                        "nullableValue":field.nullable,
                                                        "minValue":minValue,
                                                        "maxValue":maxValue,
                                                        "canShowEditIcon":nameValues.length === 0 && field.fieldType !== Enums.FieldTypeDate,
                                                        "canShowCalendarIcon":field.fieldType === Enums.FieldTypeDate,
                                                        "canShowDomainIcon":nameValues.length > 0

                                                    })
                    }

                }
            }

        }

        return feature1
    }


    function isFieldEditable(popupManager,fieldName)
    {
        let isEditable = false
        let fields = popupManager.popup.popupDefinition.fields
        for(let key = 0;key <fields.length;key ++)
        {
            let field = fields[key]//fields.get(key)
            if(field.fieldName === fieldName)
                return field.editable
        }
        return isEditable
    }


}

