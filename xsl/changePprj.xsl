<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pfldata="http://data.ub.uib.no/protege3/pprj/data"
    xmlns:pfl="http://data.ub.uib.no/protege3/function-library"
    exclude-result-prefixes="xs"
    version="3.0">
    <!--
    <xsl:param name="pprj-file" as="xs:string" select="'/home/oyvind/repos/dst/projects/protege-projects/marcus-bs/marcus-bs.pprj'"></xsl:param>
    -->
    <xsl:param name="pprj-file" as="xs:string" select="'file:/C:/Users/user/Repos/dst/protege-projects/marcus-bs/marcus-bs.pprj'"></xsl:param>
   <xsl:param name="debug" as="xs:boolean" select="false()"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jun 2, 2017</xd:p>
            <xd:p>Example stylesheet which parses a pprj project and does changes to its example files.</xd:p>
        </xd:desc>
    </xd:doc>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>unparsed text pprj project file in UTF-8</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="lookup" select="'test/skeivt-arkiv-test.pprj'"/>
    <xsl:param name="project-name" select="'marcus-bs_ProjectKB_Class'"/>
    <!-- added as a global param for testing-->      
    <xsl:include href="lib/protege3-pprj-functions.xsl"/>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>For debugging change to xml</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="text" encoding="UTF-8"/>    
    
  
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Starting point, generates a result file in variable $structured-result.</xd:p>
            <xd:p>Prints model if output is changed to xml, and if debug param is set.</xd:p>
            <xd:p>A root element <xd:pre>pfldata:items</xd:pre> with mixed-contents to be used for intermediate results before changes.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/">
        
        <xsl:variable name="pprj" select="unparsed-text($pprj-file)"/>
        <!-- generate a xml representation of the pprj file, consisting of 
         items/item[all machine readable values to be used as attributes]/text()[full text of item as is]-->
        <xsl:variable name="structured-result" select="pfl:createItemsFromPprj($pprj)"/>  
      <xsl:if test="$debug"> 
       <xsl:copy-of select="$structured-result"/>
      </xsl:if>
        <xsl:variable name="change-identifiers-and-add-UUID-property-and-widget" >
        <xsl:apply-templates select="$structured-result" mode="IdentifiersAndUUID">          
            <xsl:with-param name="starting-number" select="pfl:getNextItemNumber($pprj)" tunnel="yes"/>
        </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="add-class-hierarchy-widget">
        <xsl:apply-templates select="$change-identifiers-and-add-UUID-property-and-widget" mode="classHierarchyWidget">
            <xsl:with-param name="starting-number" select="pfl:getNextItemNumber(string($change-identifiers-and-add-UUID-property-and-widget))" tunnel="yes"></xsl:with-param>
        </xsl:apply-templates>
        </xsl:variable>
            
        <xsl:apply-templates select="$add-class-hierarchy-widget" mode="to-text"/>        
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Template match of a propertylist which is for an ontology Class (i.e traverse to find out if something should be added).</xd:p>
        </xd:desc>
        <xd:param name="widget-for-all">param name</xd:param>
    </xd:doc>
    
    <!-- each update has its own mode, have a result variable as element(items), and apply next change to it. 
        Solves issue with counting for creating new values.
        -->
    
    <!-- basic copy of select match to keep values between iterations, add mode for new changes-->
    <xsl:template match="*" mode="update-UUIDWidget classHierarchyWidget IdentifiersAndUUID">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>    
  
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Adding ClassHierarchyURIWidget</xd:p>
        </xd:desc>
        <xd:param name="starting-number"></xd:param>
    </xd:doc>
    <xsl:template match="pfldata:item[@properties 
        and 
        pfl:isPropertylistForOntology(self::pfldata:item,$ubbont-document)
       and not(pfl:itemHasPropertyWithWidget(self::node(),'edu.stanford.smi.protegex.owl.ui.widget.ClassHierarchyURIWidget')) ]" mode="classHierarchyWidget">
        <xsl:param name="starting-number" tunnel="yes" as="xs:integer"/>
        <xsl:variable name="position" as="xs:integer">
            <xsl:number count="pfldata:item[@properties 
                and pfl:isPropertylistForOntology(self::pfldata:item,$ubbont-document)
                and not(pfl:itemHasPropertyWithWidget(self::node(),'edu.stanford.smi.protegex.owl.ui.widget.ClassHierarchyURIWidget')) ]"/>
        </xsl:variable>
        <xsl:variable name="next-number" select="$starting-number+$position" as="xs:integer"/>                
        <xsl:variable name="next-item" select="pfl:itemObjectNameFromValue(concat($project-name,$next-number))" as="xs:string"/>      
        <xsl:variable name="updated-item" as="element(pfldata:item)">                
            <xsl:sequence select="pfl:addPointerToPropertyList(self::node(),$next-item)"/>
        </xsl:variable>
        <xsl:variable name="new-item" select="pfl:addItem('Widget',$next-item)"/>
            
        <xsl:variable name="do-changes" select="
            pfl:addPropertyToItem(
            pfl:addPropertyToItem(
            pfl:addPropertyToItem(
            pfl:addPropertyToItem(
            pfl:addPropertyToItem($new-item
            ,'name','http://data.ub.uib.no/ontology/classHierarchyURI')
            ,'widget_class_name','edu.stanford.smi.protegex.owl.ui.widget.ClassHierarchyURIWidget')
            ,'width','0')
            ,'height','0')
            ,'is_hidden','TRUE') "/>
        
        <xsl:copy-of select="$updated-item"/>        
        <xsl:copy-of select="$do-changes"/>        
    </xsl:template>
   
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Adding UUID widget to pprj.</xd:p>
        </xd:desc>
        <xd:param name="starting-number"></xd:param>
    </xd:doc>
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
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Update identifier widget if it is not the wanted widget. Apply result once more, to write text version or other match. </xd:p>
            <xd:p>note: make sure that the third argument of itemNeeds is the same as widget to be added to avoid eternal loop.</xd:p>
        </xd:desc>
        <xd:param name="items"></xd:param>
    </xd:doc>
    <xsl:template match="pfldata:item[@name='http://purl.org/dc/terms/identifier' and not(pfl:itemPropertyHasWidget(self::node(),'http://purl.org/dc/terms/identifier','edu.stanford.smi.protegex.owl.ui.widget.UBBSignatureWidget'))]" mode="IdentifiersAndUUID">
        <xsl:variable name="add-identifier-widget" select="not(pfl:itemPropertyHasWidget(self::node(),'http://purl.org/dc/terms/identifier','edu.stanford.smi.protegex.owl.ui.widget.UBBSignatureWidget'))"/>
        <xsl:variable name="item-with-removed-widget" as="element(pfldata:item)" select="pfl:removePropertyFromItem(self::node(),'widget_class_name')"/>
        <xsl:variable name="item-with-added-new-widget"  select="pfl:addPropertyToItem($item-with-removed-widget,'widget_class_name','edu.stanford.smi.protegex.owl.ui.widget.UBBSignatureWidget')"/>
        <xsl:copy-of select="$item-with-added-new-widget"/>
    </xsl:template>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Mode to change back to text (strip element and attributes)</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="*:item|*" mode="to-text">
        <xsl:apply-templates mode="to-text"/>
    </xsl:template>
  
</xsl:stylesheet>
