import QtQuick 2.0
import Esri.ArcGISRuntime 100.14

Item {
    id:contingencyValues
    property var contingentFieldGroups:({})
    property var contingentgroupmembers:({})



   // The contingentValuesDefinition property in a featureTable must be loaded before it can be accessed and needs
   // to be loaded after the table is loaded
    function loadContingentValuesDefinition(_featTable)
    {
        if(_featTable.loadStatus === Enums.LoadStatusLoaded && _featTable.contingentValuesDefinition.loadStatus !== Enums.LoadStatusLoaded)
        {
            _featTable.featureRequestMode = Enums.FeatureRequestModeOnInteractionNoCache
            _featTable.contingentValuesDefinition.load()
        }
        else
        {
            _featTable.loadStatusChanged.connect(function()
            {
                if(_featTable.loadStatus === Enums.LoadStatusLoaded)
                {
                    _featTable.featureRequestMode = Enums.FeatureRequestModeOnInteractionNoCache
                    _featTable.contingentValuesDefinition.load()
                }


            })
            _featTable.featureRequestMode = Enums.FeatureRequestModeOnInteractionNoCache
            _featTable.load()
        }
    }

    /*
       This function  uses the Runtime to fetch the recommended Values of any field .
       But it does not work very well if any field in the field group has null values. So is not used currently

    */
    function getFieldContingentValues(inFeature,fieldName) {
        let _featTable = inFeature.featureTable
        let fieldGroup = getFieldGroup(fieldName)
        const contingentValuesResult = _featTable.contingentValues(inFeature, fieldName);
        const contingentValuesList = contingentValuesResult.contingentValuesByFieldGroup[fieldGroup];

        const returnList = [];
        if(contingentValuesList)
        {

            contingentValuesList.forEach(contingentValue => {
                                             if (contingentValue.objectType === Enums.ContingentValueTypeContingentCodedValue) {
                                                 returnList.push({"category":strings.recommended_text,"name":contingentValue.codedValue.name,"showInView":true});
                                             } else if (contingentValue.objectType === Enums.ContingentValueTypeContingentRangeValue) {
                                                 returnList.push(contingentValue.minValue);
                                                 returnList.push(contingentValue.maxValue);
                                             }
                                         });
        }
        return returnList;
    }



    function populateContingencyFieldGroupMembers(_featTable)
    {
        if(_featTable.contingentValuesDefinition)
        {
            let fieldsdefinition = _featTable.contingentValuesDefinition
            if(fieldsdefinition.fieldGroups && fieldsdefinition.fieldGroups.length > 0)
            {
                for(let k=0;k<fieldsdefinition.fieldGroups.length;k++)
                {
                    let fldgrp = fieldsdefinition.fieldGroups[k]
                    let fldgrpname = fldgrp.name
                    contingentFieldGroups[fldgrpname] = []
                    let contingencies = fldgrp.contingencies
                    // for(let p = 0;p<contingencies.length;p++)
                    if(contingencies.length)
                    {
                        let contingency = contingencies[0]
                        let contingentvalues = contingencies[0].values
                        for(var key in contingentvalues)
                        {
                            if(contingentgroupmembers[fldgrpname])
                            {
                                if(!contingentgroupmembers[fldgrpname].includes(key))
                                    contingentgroupmembers[fldgrpname] .push(key)
                            }
                            else
                            {
                                contingentgroupmembers[fldgrpname] = []
                                contingentgroupmembers[fldgrpname] .push(key)
                            }
                        }

                    }


                }
            }
        }

    }


    /*
      populate a dictionary <contingentFieldGroups,<valueList>>  of contingent values for each field group to be used to get the recommended
      values of any field and also create a dictionary of fieldGroup and list of fields in that group.

    */

    function prepareContingentValueList(featureTable)
    {
        //<fieldgroup>< [<{field1_code,field1_value},field2,field3>]>
        //<fieldgroup,[fieldnames]>
        //1. need to identify the fieldgroup
        //2. create the compatible fieldvalues
        //3.if the existing combination is not present mark the fields as invalid. it can also be obtained by calling a function
        //val contingentValueViolations = polesTable.validateContingencyConstraints(newFeature)
        if(featureTable.contingentValuesDefinition)
        {
            let fieldsdefinition = featureTable.contingentValuesDefinition
            if(fieldsdefinition.fieldGroups && fieldsdefinition.fieldGroups.length > 0)
            {
                for(let k=0;k<fieldsdefinition.fieldGroups.length;k++)
                {
                    let fldgrp = fieldsdefinition.fieldGroups[k]
                    let fldgrpname = fldgrp.name
                    contingentFieldGroups[fldgrpname] = []
                    let contingencies = fldgrp.contingencies
                    for(let p = 0;p<contingencies.length;p++)
                    {
                        let contingency = contingencies[p]

                        if(!contingency.retired) {
                            //get the subtype
                            let _record = {}
                            if(contingency.subtype)
                            {
                                let _subtype = contingency.subtype
                                let _subtypeField = featureTable.subtypeField
                                _record[_subtypeField] = _subtype.name
                            }

                            let contingentvalues = contingencies[p].values

                            for(var key in contingentvalues)
                            {
                                let fldname = key
                                let valueObject = contingentvalues[key]

                                if(valueObject.objectType === Enums.ContingentValueTypeContingentCodedValue)
                                {
                                    let _codedVal = valueObject.codedValue
                                    let _name = _codedVal.name

                                    _record[key] = _name

                                }
                                if(contingentgroupmembers[fldgrpname])
                                {
                                    if(!contingentgroupmembers[fldgrpname].includes(key))
                                        contingentgroupmembers[fldgrpname] .push(key)
                                }
                                else
                                {
                                    contingentgroupmembers[fldgrpname] = []
                                    contingentgroupmembers[fldgrpname] .push(key)
                                }


                            }
                            contingentFieldGroups[fldgrpname].push(_record)


                        }
                    }

                }

            }
        }


    }

    function getFieldGroup(fieldName)
    {
        let fldGrp
        for (let fldgrp in contingentgroupmembers)
        {
            let _flds = contingentgroupmembers[fldgrp]
            if((_flds) && _flds.includes(fieldName))
                fldGrp  = fldgrp
            return fldGrp

        }
        return fldGrp
    }

    //This function  fetches the recommended Values of any target field based on the
    //values of other fields in the field group .
    function getContingentValues(targetfieldName,feature,featureTypeField)
    {
        let recommendedValues = []
        let _featureTable = feature.featureTable

        let fldGroup = getFieldGroup(targetfieldName)
        if(fldGroup)
        {
            let compatiblefieldList =  contingentFieldGroups[fldGroup]
            let _flds = contingentgroupmembers[fldGroup]
            //get the name for other fields in the fieldgroup
            let restOfTheFields = _flds.filter(fld => fld !== targetfieldName)
            //create the expression to filter the recommendations for target field
            let expr = ""
            let fldGroupObj = {}
            restOfTheFields.forEach(function(fld){
                let _val = feature.attributes.attributeValue(fld)
                //get the domain name if it is a domain field
                if(_val !== null)
                {
                    let fldValue =  mapViewerCore.getDomainNameFromFeatureTable(_featureTable,fld,_val)
                    fldGroupObj[fld] = fldValue
                }

            }
            )

            let featureType = feature.attributes.attributeValue(featureTypeField)
            //get the domain name for featureType
            let featureTypeName = mapViewerCore.getDomainNameFromFeatureTable(_featureTable,featureTypeField,featureType)
            let _filteredRecords = [...compatiblefieldList]

            for(let key in fldGroupObj)
            {
                if(key !== targetfieldName){
                    let _fldval = fldGroupObj[key]
                    if(_fldval !== "Unknown")
                        _filteredRecords = filterRecords(_filteredRecords,key,_fldval)
                }

            }
            //need to filter based on subtype
            if(compatiblefieldList.length === _filteredRecords.length)
            recommendedValues = []
            else

            recommendedValues = extractRecordsForField(targetfieldName,_filteredRecords)

        }
        return recommendedValues
    }

    function filterRecords(records,key,value){
        let _newRecords = records.filter(obj => obj[key] === value)
        return _newRecords
    }

   //populates the recommended values
    function extractRecordsForField(targetField,records)
    {
        let recommendedValues = []
        records.forEach(function(obj){
            let fldval = obj[targetField]
            if(fldval !== "Unknown")
            {
                let _isFieldFound = recommendedValues.filter(obj => obj.name === fldval)
                if(_isFieldFound.length === 0 && fldval)
                    recommendedValues.push({"category":strings.recommended_text, "name":fldval,"showInView":true})
            }
        }
        )

        return recommendedValues
    }



    function validateContingentValues(feature) {
        let _featTable = feature.featureTable
        let errorType = ""
        if(_featTable)
        {
            const contingencyConstraintsViolationList = _featTable.validateContingencyConstraints(feature)
            if (contingencyConstraintsViolationList.length > 0)
                errorType = "Warning"
            for(let k=0;k<contingencyConstraintsViolationList.length;k++)
            {
                let _violation = contingencyConstraintsViolationList[k]
                if(_violation.type === Enums.ContingencyConstraintViolationTypeError)
                    errorType = "Error"
            }
        }
        return errorType
    }

    function getFieldsInFieldGroup(_featureTable)
    {
        let fieldGroups = {}
        let _contigencyValuesDefinition = _featureTable.contingentValuesDefinition
        let _fieldGroups = _contigencyValuesDefinition.fieldGroups
        for(let _fldgrpindx in _fieldGroups)
        {
            let _fldgrp = _fieldGroups[_fldgrpindx]
            let grpname = _fldgrp.name
            let fields = _fldgrp.fields
            fieldGroups[grpname] = fields
        }
        return fieldGroups

    }

    function findInvalidContingencyFieldGroups(feature)
    {
        let _featTable = feature.featureTable
        let invalidFldGrps = {}
        if(_featTable)
        {
            const contingencyConstraintsViolationList = _featTable.validateContingencyConstraints(feature)
            if (contingencyConstraintsViolationList.length > 0)
            {

                for(let k=0;k<contingencyConstraintsViolationList.length;k++){
                    let violation = contingencyConstraintsViolationList[k]
                    let fieldGroup = violation.fieldGroup.name
                    invalidFldGrps[fieldGroup] = violation

                }
            }
        }
        return invalidFldGrps
    }

}
