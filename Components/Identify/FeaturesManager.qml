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

    function updateLicenseIfLite(portalItem,_portal)
    {
        let _portalInfo = _portal.portalInfo
        //check if the user has the edit privilege
        if(_portal.portalUser && !userHasEditRole)
        {
            for(var i=0;i<_portal.portalUser.privileges.count;i++)
            {
                let type = _portal.portalUser.privileges.get(i).type
                if(type === 0){

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


                portal.fetchLicenseInfoStatusChanged.connect(()=>{
                                                                 if (portal.fetchLicenseInfoStatus === Enums.TaskStatusCompleted) {
                                                                     const licenseInfo = portal.fetchLicenseInfoResult;

                                                                     let licenseResult = ArcGISRuntimeEnvironment.setLicense(licenseInfo)

                                                                 }
                                                             });
                portal.fetchLicenseInfo();




            }

        }
    }
    
    function checkEditPermissions(identifiedFeature,portalItem,_portal)
    {
        return new Promise((resolve, reject)=>{
                               let isEditable = false
                               let hasEditRole = false
                               let isFeatureTableEditable = false
                               // if(app.isSignedIn)
                               // {

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

                                           // console.log("type:",portal.portalUser.privileges.get(i).type,portal.portalUser.privileges.get(i).typeName,"role:",portal.portalUser.privileges.get(i).role)
                                       }
                                   }
                                   if(userHasEditRole)
                                   {
                                       //for lite license get the userType
                                       if (ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelLite)
                                       {


                                           portal.fetchLicenseInfoStatusChanged.connect(()=>{
                                                                                            if (portal.fetchLicenseInfoStatus === Enums.TaskStatusCompleted) {
                                                                                                const licenseInfo = portal.fetchLicenseInfoResult;

                                                                                                let licenseResult = ArcGISRuntimeEnvironment.setLicense(licenseInfo)
                                                                                                //check license
                                                                                                if ((ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelBasic) ||
                                                                                                    (ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelStandard) ||
                                                                                                    (ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelDeveloper)
                                                                                                    ||(ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelAdvanced)) {
                                                                                                    if(isFeatureTableEditable)
                                                                                                    isEditable = true
                                                                                                    resolve(isEditable)


                                                                                                }


                                                                                            }
                                                                                        });
                                           portal.fetchLicenseInfo();

                                       }
                                       else
                                       {


                                           //check license
                                           if ((ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelBasic) ||
                                               (ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelStandard) ||
                                               (ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelDeveloper)
                                               ||(ArcGISRuntimeEnvironment.license.licenseLevel === Enums.LicenseLevelAdvanced)) {
                                               if(isFeatureTableEditable)
                                               isEditable = true
                                               resolve(isEditable)


                                           }
                                       }
                                   }
                                   else
                                   {
                                       if(portalItem.access === "public")
                                       isEditable = true
                                       else
                                       isEditable = false

                                       resolve(isEditable)
                                   }



                               }
                               else
                               {
                                   isEditable = false
                                   console.log("license",ArcGISRuntimeEnvironment.license.licenseLevel)
                                   resolve(isEditable)

                               }

                               //console.log("license",ArcGISRuntimeEnvironment.license.licenseLevel)
                               // return isEditable
                           })
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
    
    function isFeatureValid(feature)
    {
        let _featTable = feature.featureTable

    }

    function isFieldPresentInFieldGroup(fieldname,fieldGroupName,contingencyfldGrps)
    {
        let _flds = contingencyfldGrps[fieldGroupName]
        if(_flds && _flds.includes(fieldname))
            return true
        else
            return false

    }

    function updateFeatureWithDomains(existingRecord,newEditObject,featureTable,currentlyEditedFeature)
    {
        //need to check if the user changes a featureType then we need to
        //update the domain values of other fields which is depended on that
        // let existingRecord = identifyManager.attrListModel.get(k)//obj
        let featureTypeField = featureTable.typeIdField
        if(newEditObject.fieldName === featureTable.typeIdField && existingRecord.fieldName !== newEditObject.fieldName)
        {


            let {codedValues, nameValues,_fieldVal,_fieldVal_code} = featuresManager.updateFieldDomain(featureTable,newEditObject.fieldValue,existingRecord.fieldName)
            //now get the Recommended values and update the domain based on contingent values
            //get the fieldgroup
            if(_fieldVal)
            {
                existingRecord["fieldValue"] =_fieldVal.toString() // ? _fieldVal.toString() : null

                let fldValToReplace = _fieldVal_code
                //the currentfeature will be replaced by the new value if the domain is defined under the featureType
                currentlyEditedFeature.attributes.replaceAttribute(existingRecord.fieldName, fldValToReplace);
            }



            if(codedValues.length > 0)
            {
                existingRecord["domainCode"] = codedValues
                existingRecord["domainName"] = nameValues
                existingRecord["unformattedValue"] = typeof _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null"
                existingRecord["editedValue"] = typeof _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null"


            }
        }
        else if(existingRecord.fieldName === newEditObject.fieldName)
        {
            let _editedfieldVal = newEditObject.fieldValue
            if(_editedfieldVal === strings.no_value)
                _editedfieldVal = null
            else
                _editedfieldVal = newEditObject.fieldValue.toString()



            existingRecord["unformattedValue"] =_editedfieldVal //newEditObject.fieldValue.toString()
            existingRecord["editedValue"] = _editedfieldVal//newEditObject.fieldValue.toString()
            existingRecord["fieldValue"] = _editedfieldVal//newEditObject.fieldValue.toString()

        }

        if(!existingRecord.fieldName)
        {
            //console.log("hello")
        }
        else
        {
            //let fieldRecommendedValues = contingencyValues.getFieldContingentValues(currentlyEditedFeature,existingRecord.fieldName)
            let fieldRecommendedValues = contingencyValues.getContingentValues(existingRecord.fieldName,currentlyEditedFeature,featureTypeField)
            let featureTypeFieldValue = currentlyEditedFeature.attributes.attributeValue(featureTypeField)
            let fielddomainnames = featuresManager.getFieldDomains(featureTable,featureTypeFieldValue,existingRecord.fieldName)//existingRecord["domainName"]
            //need to get the domainnames for the field

            let combinedArray = featuresManager.concatenateDomainValues(fieldRecommendedValues,fielddomainnames)
            existingRecord["domainName"] = combinedArray

        }



        //check if it is invalid based on contingentvalues
        let fieldValidype = featuresManager.getFieldValidType(currentlyEditedFeature,existingRecord.fieldName)

        existingRecord["fieldValidType"] = fieldValidype

        // return({currentlyEditedFeature,existingRecord})

    }

    function populateDomainValues(field,feature1)
    {
        let _codedValues = []//field.domain
        let _nameValues = []
        let minValue = 0
        let maxValue = 0
        let fldname = ""
        let subtypeField = feature1.featureTable?feature1.featureTable.typeIdField : ""
        if(field.name)
            fldname = field.name
        else
            fldname = field.fieldName


        if(subtypeField && subtypeField.toUpperCase() === fldname.toUpperCase())
        {
            let codedValues_subtypes = getSubtypesFromFeatureTable(feature1.featureTable)//getSubtypes(feature1) //populateSubTypeDomains(feature1)


            codedValues_subtypes.forEach(element => {
                                             _codedValues.push({"code":element.code?element.code.toString():"-1"})
                                             _nameValues.push({"name":element.name,"category":"","showInView":true})
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

                                _nameValues.push({"name":"None","category":"","showInView":true})
                            }
                        }

                        for(var k=0;k<domainObj.length;k++)
                        {

                            _codedValues.push({"code":domainObj[k].code.toString()})
                            _nameValues.push({"name":domainObj[k].name,"category":"","showInView":true})
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

                        _codedValues = coded_name_ValuesObj.codedValues

                        _nameValues = coded_name_ValuesObj.nameValues

                    }
                }


            }



        }
        let fieldRecommendedValues = contingencyValues.getContingentValues(fldname,feature1,subtypeField)

        let combinedArray = concatenateDomainValues(fieldRecommendedValues,_nameValues)
        _nameValues = combinedArray


        return {_nameValues,_codedValues,minValue,maxValue}

    }

    function concatenateDomainValues(fieldRecommendedValues,fielddomainnames)
    {
        let _combinedArray = []
        if(fieldRecommendedValues.length > 0 || fielddomainnames.length > 0 || fielddomainnames.count > 0)
        {
            _combinedArray.push({"name":strings.no_value, "category":"","showInView":true})
            fieldRecommendedValues.forEach(function(obj){
                _combinedArray.push(obj)
            }
            )
            let noOfRecords = fielddomainnames.length
            if(!noOfRecords)
                noOfRecords = fielddomainnames.count
            let expandOthers = false
            if(fieldRecommendedValues.length === 0)
                expandOthers = true

            //if(fielddomainnames.length){
            for(let k=0;k<noOfRecords;k++)
            {
                let record = fielddomainnames[k]
                if(record["name"] !== "None")
                {

                    let existingObjects = _combinedArray.filter(obj => obj.name === record["name"])
                    if(existingObjects.length === 0)
                        _combinedArray.push({"name":record["name"], "category":strings.others_text,"showInView":expandOthers})
                }

            }

        }

        return _combinedArray


    }

    function getFieldValidType(feature1,fldname)
    {
        let fieldValidType = ""
        let _featTable = feature1.featureTable
        let contingencyfldGrps = contingencyValues.getFieldsInFieldGroup(_featTable)
        let contigencyValidType = contingencyValues.validateContingentValues(feature1)

        let invalidfldGrps_violationMap

        if(contigencyValidType > "")
        {
            //find the fieldgroup not valid and then mark all the fields in the group invalid.
            invalidfldGrps_violationMap = contingencyValues.findInvalidContingencyFieldGroups(feature1)
        }


        for(let key in invalidfldGrps_violationMap)
        {
            let grp = key
            let violationType = invalidfldGrps_violationMap[key].type
            let _isFieldPresent = isFieldPresentInFieldGroup(fldname,grp,contingencyfldGrps)
            if(_isFieldPresent)
            {
                if(violationType === Enums.ContingencyConstraintViolationTypeError)
                    fieldValidType = "Error"
                else
                    fieldValidType = "Warning"
                break
            }

        }

        return fieldValidType
    }

    function getFieldValueFromFeatureTable(feature1,fields,field,subtype_domains)
    {
        let fldname = ""
        let attributeJson1 = feature1.attributes.attributesJson
        if(field.name)
            fldname = field.name
        else
            fldname = field.fieldName
        let _fieldVal = attributeJson1[fldname]

        // check if is a domain field. domain can be at the field level or featuretypes level

        if(field.domain){
            let fieldValAttrJson = utilityFunctions.getCodedValue(fields,fldname,_fieldVal)
            let fldType =   field.fieldType
            _fieldVal = utilityFunctions.getFormattedFieldValue(fieldValAttrJson,fldType)
        }
        else
        {
            //get it from subtype_info
            if(subtype_domains)
            {
                let _fielddomains = subtype_domains[_featuretypecodedValue]
                if(_fielddomains){
                    let _domain = _fielddomains[field.name]
                    if(_domain && _domain.codedValues)
                    {
                        let _subcodedValues = _domain.codedValues
                        let fieldValue = attributeJson1[fldname]

                        for(var x=0;x<_subcodedValues.length;x++)
                        {
                            if(_subcodedValues[x].code  ===  fieldValue)
                            {
                                var codedValueObj = _subcodedValues[x]
                                let _fieldVal1 = codedValueObj.name
                                let fldType =   field.fieldType
                                _fieldVal = utilityFunctions.getFormattedFieldValue(_fieldVal1,fldType)
                                break

                            }
                        }

                    }
                }
            }

        }

        return _fieldVal
    }

    //this method gets called to populate fields for editing  when user goes from non edit mode to edit mode
    function populateModelForEditAttributes(feature1,attrListModel,popupManager)
    {
        attrListModel.clear()
        let _featTable = feature1.featureTable
        let subtypeField = feature1.featureTable.typeIdField
        let attributeJson1 = feature1.attributes.attributesJson
        
        let subtype_domain = []
        if(subtypeField)
        {
            let subtypeFieldValue = attributeJson1[subtypeField.toLowerCase()]
            if(!subtypeFieldValue)
                subtypeFieldValue = attributeJson1[subtypeField]

            _featuretypecodedValue =  mapViewerCore.getDomainCodeFromFeatureTable(feature1.featureTable,subtypeField,subtypeFieldValue)//mapViewerCore.getDomainCode(sketchEditorManager.currentLayerId,subtypeField,subtypeFieldValue)
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
                    popupfieldVal = identifyManager.getPopupFieldValue(popupManager,fldname)
                    let _fieldVal = popupfieldVal
                    //if not populated get it from attribute Json

                    if(!_fieldVal)
                        _fieldVal = getFieldValueFromFeatureTable(feature1,fields,field,subtype_info.subtype_domain)

                    let _fieldAlias = fldname
                    
                    if(field.label)
                        _fieldAlias = field.label
                    else if(field.alias)
                        _fieldAlias = field.alias

                    let {_nameValues,_codedValues,minValue,maxValue} =  populateDomainValues(field,feature1)
                    let length = 0
                    
                    for(var k1 = 0;k1<fields.length;k1 ++)
                    {
                        let fld = fields[k1]
                        if(fld.name === field.fieldName)
                            length = fld.length
                    }
                    //check if it is invalid based on contingentvalues
                    let fieldValidType  = getFieldValidType(feature1,fldname)
                    
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
                                             "canShowDomainIcon":_nameValues.length > 0,
                                             "fieldValidType":fieldValidType

                                             
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

    function populatedCodedValuesForFieldDomain(codedValues,nameValues,field,codedValDic)
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
                codedValDic[domainObj[k].code.toString()] =  domainObj[k].name
            }
        }
    }

    function populateCodedValuesWithDomainObject(fielddomains,codedValues,nameValues,fieldName)
    {
        if(!nameValues)
            nameValues = []
        if(!codedValues)
            codedValues = []
        if(fielddomains)
        {

            let domain = fielddomains[fieldName]
            if(domain){

                let domainValues = domain.codedValues
                if(domainValues)
                {
                    for(var k1=0;k1 < domainValues.length;k1++){
                        let subtype = domainValues[k1]                        
                        nameValues.push({"name":subtype.name,"category":"OTHER"})
                        codedValues.push({"code":subtype.code.toString()})

                    }
                }
            }
        }
        return {codedValues,nameValues}
    }

    function getFieldValueFromTemplate(_featureTable,featureTypeFieldValue,field,existingfldValue)
    {
        let featuretype = _featureTable.typeIdField
        let codedValues = []//field.domain
        let nameValues = []
        let _fieldVal = null
        let minValue=0
        let maxValue = 0
        let _fieldValcode = null
        let targetFieldName = field.name
        if(featuretype && subtype_info.subtype_templates && !existingfldValue && field.fieldType !== Enums.FieldTypeDate)
        {
            //need to get the code from name

            //get the fieldvalue from subtype templates if available

            let fieldTemplate = subtype_info.subtype_templates[featureTypeFieldValue]

            if(fieldTemplate)
                _fieldValcode = fieldTemplate[targetFieldName]

        }

        if(field.fieldType !== Enums.FieldTypeDate){
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
        }


        return _fieldValcode

    }

    function updateFieldDomainBasedOnContingentValues(_featureTable,featureTypeFieldValue,targetFieldName)
    {
        let _contigentvaluesDef = _featureTable.contingentValuesDefinition
        //let fldGroups =
    }

    function getDomainFromField(field)
    {
        let nameValues = []
        let domain = field.domain
        if(domain){

            let domainValues = domain.codedValues
            if(domainValues)
            {
                for(var k1=0;k1 < domainValues.length;k1++){
                    let domainObj = domainValues[k1]
                    {

                        nameValues.push({"name":domainObj.name,"category":"","showInView":true})

                    }
                }
            }
        }
        return nameValues
    }

    function getFieldDomains(_featureTable,featureTypeFieldValue,targetFieldName)
    {
        let domainValues = []
        let featuretype = _featureTable.typeIdField
        //get the field
        let fields = _featureTable.fields

        for(var key in fields)
        {
            let field = fields[key]
            if(field.name === targetFieldName)
            {

                //1. Check if it is a domain field
                let domain = field.domain
                if(domain){

                    let nameValues = getDomainFromField(field)
                    domainValues = nameValues
                    return domainValues
                }
                else if(targetFieldName === featuretype)
                {
                    //2.Check if it is a featureType field
                    let codedValues_subtypes = getSubtypesFromFeatureTable(_featureTable)

                    codedValues_subtypes.forEach(element => {
                                                     domainValues.push({"name":element.name})
                                                 }
                                                 )

                    return domainValues
                }
                else
                {

                    //3. Check if it is a subtype domain and not a featureType field
                    if(featuretype && subtype_info.subtype_domain && targetFieldName !== featuretype)
                    {
                        //need to get the code from name
                        let _featuretypecodedValue = mapViewerCore.getDomainCodeFromFeatureTable(_featureTable,featuretype,featureTypeFieldValue)

                        let fielddomains = subtype_info.subtype_domain[_featuretypecodedValue]

                        let {nameValues} = populateCodedValuesWithDomainObject(fielddomains,null,null,targetFieldName)
                        domainValues = nameValues
                        return domainValues
                    }
                }
            }
        }
        return domainValues


    }


    function updateFieldDomain(_featureTable,featureTypeFieldValue,targetFieldName)
    {
        let featuretype = _featureTable.typeIdField
        let codedValues = []//field.domain
        let nameValues = []
        let _fieldVal = null
        let _fieldVal_code = null
        let minValue=0
        let maxValue = 0
        if(featuretype && subtype_info.subtype_domain)
        {
            //need to get the code from name
            let _featuretypecodedValue = mapViewerCore.getDomainCodeFromFeatureTable(_featureTable,featuretype,featureTypeFieldValue)//mapViewerCore.getDomainCode(sketchEditorManager.currentLayerId,featuretype,featureTypeFieldValue)

            let fielddomains = subtype_info.subtype_domain[_featuretypecodedValue]
            if(fielddomains)
            {
                //if domain is defined under featureType
                populateCodedValuesWithDomainObject(fielddomains,codedValues,nameValues,targetFieldName)

            }
            //get the fieldvalue from subtype templates if available
            if(subtype_info.subtype_templates)
            {


                let fieldTemplate = subtype_info.subtype_templates[_featuretypecodedValue]

                if(fieldTemplate){

                    let _fieldValcode  //fieldTemplate[targetFieldName]

                    //let field_domains = subtype_info.subtype_domain[_featuretypecodedValue]
                    let _domain = fielddomains[targetFieldName]
                    if(_domain && _domain.codedValues)
                    {
                        _fieldValcode = fieldTemplate[targetFieldName]
                        for(var x=0;x<_domain.codedValues.length;x++)
                        {
                            if(_domain.codedValues[x].code  ===  _fieldValcode)
                            {
                                let codedValueObj = codedValues[x]
                                _fieldVal = codedValueObj.name
                                _fieldVal_code = codedValueObj.code
                            }
                        }
                        if(!_fieldVal && _domain)
                        {
                            _fieldVal = _domain.codedValues[0].name
                            _fieldVal_code = _domain.codedValues[0].code
                        }
                    }

                }
            }

        }
        if(!_fieldVal_code && _fieldVal_code !== null)
            _fieldVal_code = _fieldVal


        return {codedValues, nameValues,_fieldVal,_fieldVal_code}


    }

    function updateCurrentFeatureFromFeatureTemplate(_featureTable,fldname,_fieldVal,_currentFeature,editFeatureType)
    {
        if(_featureTable.featureTemplates && _featureTable.featureTemplates.length > 0)
        {
            for(let k = 0;k<_featureTable.featureTemplates.length; k++)
            {
                let _template = _featureTable.featureTemplates[k]
                if(_template.name === editFeatureType)
                {
                    let _protoTypeAttribs = _template.prototypeAttributes

                    let _fldvalFromPrototype = _protoTypeAttribs[fldname.toUpperCase()]
                    if(!_fldvalFromPrototype)
                        _fldvalFromPrototype = _protoTypeAttribs[fldname]
                    if(_fldvalFromPrototype)
                    {
                        _fieldVal = mapViewerCore.getDomainCodeFromFeatureTable(_featureTable,fldname,_fldvalFromPrototype)
                        _currentFeature.attributes.replaceAttribute(fldname, _fldvalFromPrototype);

                    }
                    break

                }
            }

        }
        return {"fieldVal":_fieldVal, "currentFeature": _currentFeature}

    }

    function populateModelForEditAttributesNewFeature(_featureTable,_newfeature,subtypeFieldValue,attrListModel)
    {
        attrListModel.clear()

        let _currentFeature = sketchEditorManager.newFeatureObject["feature"]
        // _currentFeature.featureTable.contingentValuesDefinition.load()
        contingencyValues.prepareContingentValueList(_currentFeature.featureTable)
        let notNullableFiellds = []
        _featuretypecodedValue = null
        subtype_info = {}

        let featuretype = _featureTable.typeIdField

        if(featuretype)
        {
            _featuretypecodedValue =  mapViewerCore.getDomainCode(sketchEditorManager.currentLayerId,featuretype,subtypeFieldValue)
            subtype_info = populateSubTypeDomainsFromFeatureTable(_featureTable,subtypeFieldValue)
        }

        //check if the legend is based on typeid field
        //
        let isBasedOnSubtypeField  = isLegendBasedOnFeatureType(_featureTable)


        let fields =  _featureTable.editableAttributeFields//_featureTable.fields

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
                let popupDefinition = _featureTable.popupDefinition
                if(!popupDefinition)
                    popupDefinition = ArcGISRuntimeEnvironment.createObject("PopupDefinition", {initGeoElement: _newfeature})

                let popUp = ArcGISRuntimeEnvironment.createObject("Popup", {initGeoElement: _newfeature, initPopupDefinition: popupDefinition})
                let popupManager = ArcGISRuntimeEnvironment.createObject("PopupManager", {popup: popUp})

                 let isEditEnabledInPopup = isFieldEditable(popupManager,fldname)

                if(!(exprfld.length > 1) && field.editable && isEditEnabledInPopup)
                {

                    let _fieldVal = ""


                    let _fieldAlias = fldname

                    if(field.label)
                        _fieldAlias = field.label
                    else if(field.alias)
                        _fieldAlias = field.alias

                    //get the domains if it has a domain
                    let codedValDic = {}

                    let {_nameValues,_codedValues,minValue,maxValue} =  populateDomainValues(field,_currentFeature)
                    let length = 0

                    for(var k1 = 0;k1<fields.length;k1 ++)
                    {
                        let fld = fields[k1]
                        if(fld.name === field.fieldName)
                            length = fld.length
                    }
                    //check if it is invalid based on contingentvalues
                    let fieldValidType  = getFieldValidType(_currentFeature,fldname)


                    if(!field.nullable && _nameValues.length > 0 && !_fieldVal.trim() > "")
                    {

                        _fieldVal = _nameValues[1].name

                    }
                    if(!(featuretype && featuretype.toUpperCase() === fldname.toUpperCase()))

                        _currentFeature.attributes.replaceAttribute(fldname, _fieldVal);


                    if(featuretype > "" && fldname.toUpperCase() === featuretype.toUpperCase()){

                        _fieldVal = sketchEditorManager.currentTypeName

                        //need to get the subtype filedcode
                        // let _subtypecodedValue =  mapViewerCore.getDomainCodeFromFeatureTable(_featureTable,featuretype,subtypeFieldValue)//mapViewerCore.getDomainCode(sketchEditorManager.currentLayerId,subtypeField,subtypeFieldValue)


                        // _currentFeature.attributes.replaceAttribute(fldname, _subtypecodedValue)
                        _currentFeature.attributes.replaceAttribute(fldname, _featuretypecodedValue);

                    }
                    else{
                        //check for featureTemplates
                        let currentFeatureObj = updateCurrentFeatureFromFeatureTemplate(_featureTable,fldname,_fieldVal,_currentFeature,sketchEditorManager.currentTypeName)
                        _fieldVal = currentFeatureObj.fieldVal
                        _currentFeature = currentFeatureObj.currentFeature

                    }


                    sketchEditorManager.newFeatureObject["feature"] = _currentFeature

                    //if not check if is a domain field. domain can be at the field level or featuretypes level

                    attrListModel.append({
                                             "feature":_newfeature,
                                             "description":"",
                                             "fieldName":fldname,
                                             "label": _fieldAlias,
                                             "fieldValue": _fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                             "fieldType":field.fieldType,
                                             "editedValue":_fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",
                                             "isEditable":field.editable,
                                             "unformattedValue":_fieldVal !== undefined?(_fieldVal!== null? _fieldVal.toString():"null"):"null",//attributeJson1[fldname] !== null?attributeJson1[fldname].toString():"",
                                             "length":length,//field.length,
                                             "domainName":_nameValues,
                                             "domainCode":_codedValues,
                                             "nullableValue":field.nullable,
                                             "minValue":minValue,
                                             "maxValue":maxValue,
                                             "canShowEditIcon":_nameValues.length === 0 && field.fieldType !== Enums.FieldTypeDate,
                                             "canShowCalendarIcon":field.fieldType === Enums.FieldTypeDate,
                                             "canShowDomainIcon":_nameValues.length > 0,
                                             "fieldValidType":fieldValidType

                                         })
                    if(!field.nullable)
                    {
                        if(_fieldAlias)
                            notNullableFiellds.push(_fieldAlias)
                        else
                            notNullableFiellds.push(fldname)

                        sketchEditorManager.newFeatureObject["fldAliasDic"][fldname] = _fieldAlias
                    }

                }

            }
        }


        sketchEditorManager.newFeatureObject["notNullableFields"] = notNullableFiellds


    }




    //********************************** related Features functions **************************************//

    function populateSubTypeDomains(feature,subTypeCodeValue)
    {
        let subtype_domain = {}
        let subtypeField = feature.featureTable.subtypeField

        let subtypes = feature.featureTable.featureSubtypes
        for(var k=0;k<subtypes.length;k++){
            let subtype = subtypes[k]
            if(subtype.code === subTypeCodeValue)
            {
                subtype_domain = subtype.domains
                break

            }


        }
        return subtype_domain

    }

    function populateSubTypeDomainsFromFeatureTable(featureTable,subTypeCodedValue)
    {
        let subtype_domain = {}
        let subtype_templates = {}
        //let subtypeField = featureTable.subtypeField //|| featureTable.typeIdField

        let subtypes = featureTable.featureTypes//featureTable.featureSubtypes


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

            if(_templates && _templates.length)
            {
                let _name = _templates[0].name
                //if(featureTable.featureTypes)
                if(subtype.typeId)
                    subtypeNames.push({"name":_name,"code":subtype.typeId})
                else
                    subtypeNames.push({"name":_name,"code":subtype.code})
            }
            else
            {

                //if(featureTable.featureTypes)
                if(subtype.typeId)
                    subtypeNames.push({"name":subtype.name,"code":subtype.typeId})
                else
                    subtypeNames.push({"name":subtype.name,"code":subtype.code})
            }
        }
        return subtypeNames

    }


    function getSubtypes(feature)
    {
        let subtypeNames = []

        let subtypes = feature.featureTable.featureSubtypes
        for(var k=0;k<subtypes.length;k++){
            let subtype = subtypes[k]
            subtypeNames.push({"name":subtype.name,"code":subtype.code})
        }
        return subtypeNames

    }

    function isFieldEditable(popupManager,fieldName)
    {
        let isEditable = false
        if(popupManager){
            let fields = popupManager.popup.popupDefinition.fields
            for(let key = 0;key <fields.length;key ++)
            {
                let field = fields[key]//fields.get(key)
                if(field.fieldName === fieldName)
                    return field.editable
            }
        }
        return isEditable
    }

    //--------------------------------------------------------------------------
    /*
        cannot check for editorTrackingInfo to find out if it is disabled or enabled because
        trying to access feature.featureTable.serviceGeodatabase.serviceInfo.editorTrackingInfo was causing a delay in
        loading the attachments and the fetchData for the attachment was returning an error. So we are just checking for
        editFieldsInfo.
    */

    function getEditorTrackingInfo(feature)
    {
        let editorInfo = null

        if(feature.featureTable && feature.featureTable.layerInfo){

            let editFieldsInfo = feature.featureTable.layerInfo.editFieldsInfo
            let attributesJson = feature.attributes.attributesJson
            //get the editor date
            if(editFieldsInfo)
            {
                let editDate = attributesJson[editFieldsInfo.editDateField]
                let editor = attributesJson[editFieldsInfo.editorField]
                editorInfo = {}
                if(editDate){
                    let editedDate = utilityFunctions.getTimeDiff(editDate)
                    editorInfo["editedDate"] = editedDate
                }

                editorInfo["editor"] = editor
            }


        }
        return editorInfo

    }

    function getFieldValueFromFeature(_feature,name)
    {
        let featTable = _feature.featureTable
        let fldval = null
        if(featTable)
        {
            let fields = featTable.fields
            for(var key in fields)

            {
                let field = fields[key]

                let fldname = ""
                if(field.name)
                    fldname = field.name
                else
                    fldname = field.fieldName
                if(fldname === name)
                {
                    let _fldval = _feature.attributes.attributeValue(fldname)
                    if(_fldval)
                        fldval = mapViewerCore.getDomainNameFromFeatureTable(featTable,fldname,_fldval)//getDomainNameFromCodeInTable(featTable,fldname,_fldval)
                    return fldval
                }


            }

        }
        return fldval
    }

}

