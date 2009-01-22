<?xml version="1.0"?>
<!-- Edited by XMLSpy® -->
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method='html' version='1.0' encoding='UTF-8' indent='yes'/>


<xsl:variable name="icon-dir">graphics/items</xsl:variable>

<xsl:template match="/">
  <html>
  <body>
  <h2>Item Database</h2>
      <xsl:for-each select="items/item">
      <xsl:sort select="@type"/>
        <xsl:if test="@name">
          
          <p>
          <table border="1">
          <tr bgcolor="ddddff">
            <td>
              <xsl:if test="@image">
              <img src="{$icon-dir}/{@image}"/>
              </xsl:if>
            </td>
            <td colspan="3">
              <xsl:value-of select="@name"/>
            </td>
          </tr>
          
          <tr>
            <td><strong>ID: </strong><xsl:value-of select="@id"/></td>
            <td><strong>Type: </strong><xsl:value-of select="@type"/></td>
            <xsl:if test="@weapon_type">
              <td><strong>Skill: </strong><xsl:value-of select="@weapon-type"/></td>
            </xsl:if>
            <td><strong>Weight: </strong><xsl:value-of select="@weight"/></td>          
          </tr>
          
          <tr>
            <td colspan="4"><strong>Description: </strong><xsl:value-of select="@description"/></td>
          </tr>
          <tr>
            <td colspan="4"><strong>Effect: </strong><xsl:value-of select="@effect"/></td>
          </tr>
          </table>
          </p>
        </xsl:if>
      </xsl:for-each>
  </body>
  </html>
</xsl:template>
</xsl:stylesheet>