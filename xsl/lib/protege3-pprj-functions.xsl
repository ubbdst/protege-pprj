<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:pfldata="http://data.ub.uib.no/protege3/pprj/data"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:pfl="http://data.ub.uib.no/protege3/function-library"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="3.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jun 2, 2017</xd:p>
            <xd:p>Functions to manipulate pprj files for Protege 3.5</xd:p>
            
        </xd:desc>
    </xd:doc>
    
    <!-- added to param to explicitly state that is has to be overriden by xspec test (issue with global variables when running xspec)-->
    <!-- add to list and update xspec param to add additional parameters -->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Using param because of bug in unit testing framework. Global values are set as parameters by the test.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="property-list">        
        <properties>
            <property type="string" name="label"/>
            <property type="string" name="name"/>
            <property type="string" name="widget_class_name"/>
            <property type="object" name="property_list"/>            
            <property type="integer" name="width"/>
            <property type="integer" name="height"/>
            <property type="integer" name="x"/>
            <property type="integer" name="y"/>
            <property type="boolean" name="is_hidden"/>
        </properties>        
    </xsl:param>
    <!-- keys-->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>key for property list lookup</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:key name="propertyByName" use="@name" match="property"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>A key for looking up a xml representation of a item/resource in the pprj, by its @id</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:key name="itemByID" use="@id" match="pfldata:item"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>key for looking up a class by URI in an ontology</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:key name="resource" use="@rdf:about" match="rdf:RDF/owl:Class"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>key for looking up a class by URI in an ontology</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:key name="resource" use="@rdf:about" match="rdf:RDF/rdfs:Class"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Key for looking up a item based on having a property_list link</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:key name="propertyListForItem" match="pfldata:item" use="@property_list"/>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>UBB ontology as RDF/XML</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="ubbont-document" select="document('http://data.ub.uib.no/ontology/ubbont.owl')"/>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Regexp for firstline of an item</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="item-firstline" select="'^\(\[([^\]]+)\]\sof.+?([\S]+)'"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Regexp for content of an item </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="item-content" select="'(\r?\n\r?\n[\s\S]+?\r?\n\r?\n)'"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Regexp for an empty item</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="item-no-content" select="'(\r?\n\)\r?\n\r?\n?)'"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>full regexp for an item</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="item-regex" select="concat($item-firstline,'(',$item-content,'|',$item-no-content,')')"/>
    
    
    <!-- functions-->    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Creates a xml representation of a pprj file</xd:p>
        </xd:desc>
        <xd:param name="pprj-string"></xd:param>
        <xd:return>Returns a items root element with child item elements.</xd:return>
    </xd:doc>
    <xsl:function name="pfl:createItemsFromPprj" as="document-node(element(pfldata:items))">
        <xsl:param name="pprj-string" as="xs:string"/>
        <xsl:variable name="items"><pfldata:items>
            <xsl:analyze-string select="$pprj-string" regex="{$item-regex}" flags="m" >
                <xsl:matching-substring>
                    <item xmlns="http://data.ub.uib.no/protege3/pprj/data" id="{regex-group(1)}" project-type="{regex-group(2)}">
                        <xsl:call-template name="createProperties">
                            <xsl:with-param name="this-string" select="."></xsl:with-param>
                        </xsl:call-template>            
                        <xsl:value-of select="."/>            
                    </item>                    </xsl:matching-substring>
                <xsl:non-matching-substring><xsl:value-of select="." /></xsl:non-matching-substring>
            </xsl:analyze-string>
        </pfldata:items>
        </xsl:variable>
        <xsl:copy-of select="$items"/>
    </xsl:function>
    <!--pub-->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Checks for existence of a property in global param $property-list</xd:p>
        </xd:desc>
        <xd:param name="property"/>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:isInPropertyList" as="xs:boolean">
        <xsl:param name="property" as="xs:string"/>
        
        <xsl:if test="not(key('propertyByName',$property,$property-list))">
            <xsl:message terminate="yes">invalid input to pfl:getPropertyByName, must be one of the values<xsl:value-of select="string-join($property-list,' ')"/></xsl:message>
        </xsl:if>   
        <xsl:sequence select="true()"/>        
    </xsl:function>
    
        <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>A function which looks up an items URI, uses it to check if it is a property list for another item/ancestor::items.
            </xd:p>
        </xd:desc>
        <xd:param name="item"></xd:param>        
        <xd:return>Only returns true if input item is a property list.</xd:return>
        <xd:param name="widget">string to check if widget is present.</xd:param>
    </xd:doc>
    <xsl:function name="pfl:itemHasPropertyWithWidget" as="xs:boolean">
        <xsl:param name="item" as="element(pfldata:item)"/>
        <xsl:param name="widget" as="xs:string"/>
        
        <xsl:sequence select="some $x in tokenize($item/@properties,' ')
            satisfies  key('itemByID',$x,$item/ancestor::pfldata:items/self::node())/@widget_class_name=$widget
            "/>        
    </xsl:function>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Checks if an item has a name which is also in an ontology</xd:p>
        </xd:desc>
        <xd:param name="item"></xd:param>
        <xd:param name="ontology"></xd:param>
        <xd:return>Returns false if item is not a Property list or if item is not in</xd:return>
    </xd:doc>
    <xsl:function name="pfl:isPropertylistForOntology" as="xs:boolean">
        <xsl:param name="item" as="element(pfldata:item)"/>        
        <xsl:param name="ontology" as="node()"/>
        
        <xsl:variable name="context" select="$item/ancestor::*:items/self::node()" as="node()"/>       
        <xsl:variable name="item-which-owns-list-is-in-ontlogoy" select="key('resource',key('propertyListForItem',$item/@id,$context)/@name,$ontology)"/>
        
        <xsl:choose>
            <xsl:when test="$item/@project-type!='Property_List' or empty($item-which-owns-list-is-in-ontlogoy)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="true()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
        <xd:param name="property"></xd:param>
        <xd:param name="value"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:concatPropertyAndValue" as="xs:string">
        <xsl:param name="property" as="xs:string"/>
        <xsl:param name="value" as="xs:string"/>
       
        <xsl:variable name="type" select="key('propertyByName',$property,$property-list)/@type"/>
          
        <xsl:choose>
            <xsl:when test="not(pfl:isInPropertyList($property))">
                <!--pfl:propertyByName terminates transformation before string --><xsl:value-of select="''"/>
            </xsl:when>
            <xsl:when test="$type='string'">
                <xsl:value-of select="concat('(',$property,' &quot;',$value,'&quot;)')"/>
            </xsl:when>
            <xsl:when test="$type='integer'">
                <xsl:value-of select="concat('(',$property,' ',$value,')')"/>
            </xsl:when>
            <xsl:when test="$type='boolean' and matches($value,'^TRUE|FALSE$')">
                <xsl:value-of select="concat('(',$property,' ',$value,')')"/>
            </xsl:when>
            <xsl:otherwise><xsl:message terminate="yes">pfl:concatPropertyAndValue Illegal input value</xsl:message></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
  
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Adds an empty item element with id and project-type set.</xd:p>
        </xd:desc>
        <xd:param name="project-type"></xd:param>
        <xd:param name="id"></xd:param>
    </xd:doc>
    <xsl:function name="pfl:addItem" as="element(pfldata:item)">
        <xsl:param name="project-type"/>
        <xsl:param name="id"/>
        <pfldata:item xmlns="http://data.ub.uib.no/protege3/pprj/data" id="{$id}" project-type="{$project-type}">(<xsl:value-of select="$id"/> of  <xsl:value-of select="$project-type"/>&#xD;<xsl:text>
)

</xsl:text></pfldata:item>      
    </xsl:function>
   
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Adds a property and its value to an item. Checks if property exists.
            Does not check if value is castable as property.</xd:p>
        </xd:desc>
        <xd:param name="item"></xd:param>
        <xd:param name="property"></xd:param>
        <xd:param name="value"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:addPropertyToItem" as="element(pfldata:item)">
        <xsl:param name="item" as="element(pfldata:item)"/>
        <xsl:param name="property" as="xs:string"/>
        <xsl:param name="value" as="xs:string"/>
        
        <xsl:variable name="property-output" select="pfl:concatPropertyAndValue($property,$value)"/>
        <xsl:variable name="indent">
            <xsl:analyze-string select="$item/text()" regex="^([\s^\n]+).+(\))(\))" flags="m">
                <xsl:matching-substring><xsl:value-of select="regex-group(1)"/></xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>       
        <xsl:variable name="item-string">
                <xsl:variable name="result">
                <xsl:analyze-string select="$item/text()" regex="(\))(\))">
                <xsl:matching-substring>
                    <xsl:sequence select="regex-group(1)"/><xsl:text>                   
</xsl:text><xsl:value-of select="$indent"/><xsl:value-of select="$property-output"/><xsl:sequence select="regex-group(2)"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:sequence select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>       
            </xsl:variable>
                
                <!-- skip first line, see that there is no nonspace characters and insert property if regex matches.
-->               <xsl:analyze-string select="$result" regex="^(.+[\s]*)(\)\s*)$">
                   <xsl:matching-substring>
                       <xsl:value-of select="concat(regex-group(1),$property-output,regex-group(2))"/>
                   </xsl:matching-substring>
                    <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:variable>
          
        <xsl:sequence select="pfl:rebuildFromString($item,$item-string)"/>         
    </xsl:function>       
    
    <!-- private-->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>gets a Regex as string to Match a specific property. Terminates if property is not in param property list.</xd:p>
        </xd:desc>
        <xd:param name="property"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:getRegexFromProperty" as="xs:string">
        <xsl:param name="property" as="xs:string"/>
      
        <xsl:variable name="regex">
            <xsl:variable name="type" select="key('propertyByName',$property,$property-list)/@type"/>     
            <xsl:choose>
                <xsl:when test="string-length($type)&lt; 1">
                    <xsl:message terminate="yes">
                        pfl:getRegexFromProperty: property: <xsl:value-of select="$property"/> not in property-list: [<xsl:value-of select="string-join($property-list/descendant::property/@name,' ')"/>]
                    </xsl:message>
                </xsl:when>
                <xsl:when test="$type='string'">
                    <xsl:value-of select="concat('\(',$property,'\s[&quot;]([^&quot;]+)')"/>
                </xsl:when>
                <xsl:when test="$type='object'">
                    <xsl:value-of select="concat('\(',$property,'\s[\[]([^\]]+)\]+')"/>
                </xsl:when>
                <xsl:when test="$type='boolean'">
                    <xsl:value-of select="concat('\(',$property,'\s(FALSE|TRUE)')"/>
                </xsl:when>
                <xsl:when test="$type='integer'">
                    <xsl:value-of select="concat('\(',$property,'\s([0-9]+)')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>        
        <xsl:value-of select="$regex"/>
    </xsl:function>  
   
    <!-- public-->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Checks if item has a widget.</xd:p>
        </xd:desc>
        <xd:param name="item"></xd:param>
        <xd:param name="widget"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:itemHasWidget" as="xs:boolean">
        <xsl:param name="item" as="element(pfldata:item)"/>
        <xsl:param name="widget" as="xs:string"/>
     
        <xsl:sequence select="if ($item/@widget_class_name=$widget) then true() else false()"/>        
    </xsl:function>    
    
    <!-- public-->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Checks if items has a property</xd:p>
        </xd:desc>
        <xd:param name="item"></xd:param>
        <xd:param name="property"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:itemHasProperty" as="xs:boolean">
        <xsl:param name="item" as="element(pfldata:item)"/>
        <xsl:param name="property" as="xs:string"/>
    
        <xsl:sequence select="if ($item/@*/name()=$property ) then true() else false()"/>      
    </xsl:function>
    
    <!-- rename Property to Predicate or name?-->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Checks if a property in an item has a widget set.</xd:p>
        </xd:desc>
        <xd:param name="item"></xd:param>
        <xd:param name="property"></xd:param>
        <xd:param name="widget"></xd:param>        
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:itemPropertyHasWidget" as="xs:boolean">
        <xsl:param name="item" as="element(pfldata:item)"/>
        <xsl:param name="property" as="xs:string"/>        
        <xsl:param name="widget" as="xs:string"/>        
        
        <xsl:variable name="items" select="$item/ancestor::pfldata:items/self::node()"/>
        <xsl:choose>
            <xsl:when test="pfl:itemHasWidget($item,$widget)">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:otherwise><xsl:sequence select="false()"/></xsl:otherwise>
            <!-- move to its own function for testing if a Class has a property in its property list-->
            
            <!--     <xsl:otherwise>
                <xsl:variable name="property-list" select="key('itemByID',$item/@property_list,$items)" as="element(pfldata:item)"/>
                <xsl:sequence select="if (some $x in tokenize($property-list/@properties,'\s') 
                    satisfies  pfl:getPropertyFromString('widget_class_name',key('itemByID',$x,$items)/text())= $widget) 
                    then false()
                    else true()"/>
            </xsl:otherwise>-->
        </xsl:choose>
       </xsl:function>   
   
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Gets the value of a property From a string.</xd:p>
        </xd:desc>
        <xd:param name="property"></xd:param>
        <xd:param name="string"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <!--private-->
    <xsl:function name="pfl:getPropertyFromString" as="xs:string?" >
        <xsl:param name="property"/>
        <xsl:param name="string"/>
        <xsl:choose>
            <xsl:when test="not(pfl:isInPropertyList($property))"><!-- terminates transformation before it gets here-->></xsl:when>           
            <xsl:otherwise>
                <xsl:variable name="result">                    
                    <xsl:analyze-string select="$string" regex="{pfl:getRegexFromProperty($property)}">            
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:value-of select="string($result)"/>
            </xsl:otherwise>           
        </xsl:choose>
       
    </xsl:function>   
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Adds a pointer to a property list</xd:p>
        </xd:desc>
        <xd:param name="item"></xd:param>
        <xd:param name="pointer"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:addPointerToPropertyList" as="element(pfldata:item)">
        <xsl:param name="item" as="element(pfldata:item)"/>
        <xsl:param name="pointer"/>
        <xsl:variable name="item-string">
       <xsl:analyze-string select="$item/text()" regex="\((properties[^\)]+)(\))">
           <xsl:matching-substring>
               <xsl:value-of select="concat('(',regex-group(1))"/><xsl:text>
</xsl:text><xsl:value-of select="'		'"/><xsl:value-of select="$pointer"/><xsl:value-of select="regex-group(2)"/>
           </xsl:matching-substring>            
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
        </xsl:variable>
        <xsl:sequence select="pfl:rebuildFromString($item,$item-string)"/>
    </xsl:function>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Gets a property list from a properties string</xd:p>
        </xd:desc>
        <xd:param name="string"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:getPropertyListFromString" as="xs:string*">
        <xsl:param name="string"/>
        <xsl:variable name="properties-string" select="replace($string,'^[\s\S]+\(properties([^\)]+)\)[\s\S]+$','$1','m')"/>
        <xsl:variable name="properties">
            <xsl:analyze-string select="$properties-string" regex="\[(.+)\]">
                <xsl:matching-substring>
                    <xsl:sequence select="regex-group(1)"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:sequence select="$properties"/>
    </xsl:function>
       
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Removes a property from item</xd:p>
        </xd:desc>
        <xd:param name="item"></xd:param>
        <xd:param name="property"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:removePropertyFromItem" as="element(pfldata:item)?">
        <xsl:param name="item" as="element(pfldata:item)"/>
        <xsl:param name="property" as="xs:string"/>
        <xsl:choose>
            <!-- property not exists-->
            <xsl:when test="not(pfl:itemHasProperty($item, $property))">              
                <xsl:sequence select="$item"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="regex"
                    select="concat('.*', pfl:getRegexFromProperty($property), '.*', '&#xD;?\r?\n')"/>
                <xsl:variable name="item-string" select="replace($item/text(), $regex, '', 'm')"/>               
               <xsl:sequence select="pfl:rebuildFromString($item,$item-string)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Copies @id and project type from item, and rebuilds other attributes and contents based on item-string </xd:p>
        </xd:desc>
        <xd:param name="item"></xd:param>
        <xd:param name="item-string"></xd:param>
        <xd:return></xd:return>
    </xd:doc>
    <xsl:function name="pfl:rebuildFromString" as="element(pfldata:item)">
        <xsl:param name="item" as="element(pfldata:item)"/>
        <xsl:param name="item-string" as="xs:string"/>
        <item xmlns="http://data.ub.uib.no/protege3/pprj/data" id="{$item/@id}"
            project-type="{$item/@project-type}">
            <xsl:call-template name="createProperties">
                <xsl:with-param name="this-string" select="$item-string"/>
            </xsl:call-template>
            <xsl:sequence select="$item-string"/>
        </item>        
    </xsl:function>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Adds all regex matches to a variable and cast them as integer, and then get highest current-value +1.</xd:p>
        </xd:desc>
        <xd:param name="input-string"></xd:param>
    </xd:doc>
    <xsl:function name="pfl:getNextItemNumber" as="xs:integer">
        <xsl:param name="input-string"/>
        <xsl:variable name="numbers" as="xs:integer+">
            <xsl:analyze-string select="$input-string"  regex="ProjectKB_Class([0-9]+)">
                <xsl:matching-substring><xsl:sequence select="xs:integer(regex-group(1))"/></xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:sequence select="max($numbers)+1"/>
    </xsl:function>
    <!-- adds [ ] to a string if not first and last character is [ and ]
    -->
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
          <xd:p>Handle adding [] if not $value starts with and ends-with.</xd:p>   </xd:desc>
        <xd:param name="value">A string to be used as a pprj object name.</xd:param>
    </xd:doc>
    <xsl:function name="pfl:itemObjectNameFromValue" as="xs:string">
        <xsl:param name="value" as="xs:string"/>
        <xsl:value-of select="if (matches($value,'^\[.+\]$')) then $value else concat('[',$value,']')"/>
    </xsl:function>
    
    <!-- named templates-->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>Loops on propertyList and adds attributes if a property is present in item.</xd:p>
            <xd:p>Also builds a properties attribute with space separated entries if this-string has a properties part.</xd:p>
        </xd:desc>
        <xd:param name="this-string"></xd:param>
    </xd:doc>
    <xsl:template name="createProperties">
        <xsl:param name="this-string"/>        
        <xsl:for-each select="$property-list/descendant::property">
            <xsl:variable name="value" select="pfl:getPropertyFromString(@name,$this-string)"/>
            <xsl:if test="string($value)">
                <xsl:attribute name="{@name}" select="$value"/>
            </xsl:if>
        </xsl:for-each>
        <xsl:if test="matches($this-string,'\(properties')">
            <xsl:attribute name="properties" select="pfl:getPropertyListFromString($this-string)"/>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>