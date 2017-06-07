# Change Protege 3X pprj files

A small function library and a stylesheet for updating an existing pprj file with new properties.
Includes a ant build file which runs the transformation.

## Dependencies
Either Oxygen XML or ant

## To run

```
git clone git@gitlab.uib.no:ubbdev/protege-pprj.git
cd protege-pprj && ant
```
## How it works

[Documentation for xsl](https://ubbdst.github.io/protege-pprj/changePprj.html)

Main function pfl:createItemsFromPprj creates an xml representation of the document to update the pprj.
The model is a wrapper xml with data which could be used to be matched on:

```
<pfldata:items xmlns:pfldata="http://data.ub.uib.no/protege3/pprj/data">
<item id="marcus_ProjectKB_Class71609" project-type="Widget" property_list="marcus_ProjectKB_Class71610" widget_class_name="edu.stanford.smi.protegex.owl.ui.widget.MultiResourceWidget" height="120" width="200" x="0" y="630" properties="property1 property2">
([marcus_ProjectKB_Class71609] of  Widget

	(height 120)
	(is_hidden FALSE)
	(label "Referért av")
	(name "http://purl.org/dc/terms/isReferencedBy")
	(property_list [marcus_ProjectKB_Class71610])
	(widget_class_name "edu.stanford.smi.protegex.owl.ui.widget.MultiResourceWidget")
	(width 200)
	(x 0)
	(y 630))
</item>

<item project_type="Property_list" properties="property1 property2">
marcus_ProjectKB_Class71610 of Property_list
   (properties
		[property1]
		[property2]))
</item>
...
</pfldata:items>
```

Then we apply templates on the result of this function, and for each change which introduces new items (i.e incrementing counter) a 
new variable with the resulting pfldata:items of last apply-templates is used. `$starting-number` is max existing object number+1 of last pprj result.

```
<xsl:variable name="change-identifiers-and-add-UUID-property-and-widget" >
        <xsl:apply-templates select="$structured-result" mode="IdentifiersAndUUID">
            <xsl:with-param name="starting-number" select="pfl:getNextItemNumber($pprj)" tunnel="yes"/>
        </xsl:apply-templates>
        </xsl:variable>
``` 

Then the metadata is used to decide which items should be changed:
For instance items with dct:identifier, that does not have a signature widget, should get a widget added.
```
 <xsl:template match="pfldata:item[@name='http://purl.org/dc/terms/identifier' and not(pfl:itemPropertyHasWidget(self::node(),'http://purl.org/dc/terms/identifier','edu.stanford.smi.protegex.owl.ui.widget.UBBSignatureWidget'))]" mode="IdentifiersAndUUID">
        <xsl:variable name="add-identifier-widget" select="not(pfl:itemPropertyHasWidget(self::node(),'http://purl.org/dc/terms/identifier','edu.stanford.smi.protegex.owl.ui.widget.UBBSignatureWidget'))"/>
        <xsl:variable name="item-with-removed-widget" as="element(pfldata:item)" select="pfl:removePropertyFromItem(self::node(),'widget_class_name')"/>
        <xsl:variable name="item-with-added-new-widget"  select="pfl:addPropertyToItem($item-with-removed-widget,'widget_class_name','edu.stanford.smi.protegex.owl.ui.widget.UBBSignatureWidget')"/>
        <xsl:copy-of select="$item-with-added-new-widget"/>
    </xsl:template>
``` 

An example of updating if UUID widget is not defined, and the property is in our ontology:
```
<xsl:template match="pfldata:item[@properties 
        and pfl:isPropertylistForOntology(self::pfldata:item,$ubbont-document) 
        and not(pfl:itemHasPropertyWithWidget(self::node(),'edu.stanford.smi.protegex.owl.ui.widget.UUIDWidget'))]" mode="IdentifiersAndUUID">
        <xsl:param name="starting-number" tunnel="yes"/>        
        <xsl:variable name="position" as="xs:integer">
            <xsl:number count="pfldata:item[@properties 
                and pfl:isPropertylistForOntology(self::pfldata:item,$ubbont-document) 
                and not(pfl:itemHasPropertyWithWidget(self::node(),'edu.stanford.smi.protegex.owl.ui.widget.UUIDWidget')) ]"/>   
        </xsl:variable>                                         
        <xsl:variable name="next-number" select="$starting-number+$position" as="xs:integer"/>                
        <xsl:variable name="next-item" select="pfl:itemObjectNameFromValue(concat($project-name,$next-number))" as="xs:string"/>      
        <xsl:variable name="updated-item" as="element(pfldata:item)" select="pfl:addPointerToPropertyList(self::node(),$next-item)"/>                
        <xsl:variable name="new-item" select="pfl:addItem('Widget',$next-item)"/>                                                                  
        <xsl:variable name="do-changes" select="
            pfl:addPropertyToItem(
            pfl:addPropertyToItem(
            pfl:addPropertyToItem(
            pfl:addPropertyToItem(
            pfl:addPropertyToItem($new-item
            ,'name','http://data.ub.uib.no/ontology/uuid')
            ,'widget_class_name','edu.stanford.smi.protegex.owl.ui.widget.UUIDWidget')
            ,'width','0')
            ,'height','0')
            ,'is_hidden','TRUE') "/>  
        <xsl:copy-of select="$updated-item"/>          
        <xsl:copy-of select="$do-changes"/>
    </xsl:template>
```    
See [protege3-pprj-functions.xsl](xsl/lib/protege3-pprj-functions.xsl).

When all updates are complete `<xsl:apply-templates select="$add-class-hierarchy-widget" mode="to-text"/>`
strips the xml elements, and the updated pprj is returned as text.

## To add new stuff

Add a new variable as intermediate result in `/` template match.
Apply templates to last result variable, with a new mode name for the change.
Add the new mode to 
```
 <xsl:template match="*" mode="update-UUIDWidget classHierarchyWidget IdentifiersAndUUID">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
```

Add the new specific change to matching template.

Change the select attribute `<xsl:apply-templates select="$add-class-hierarchy-widget" mode="to-text"/>` to the new intermediate variable name.
