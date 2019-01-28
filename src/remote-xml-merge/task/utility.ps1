function mergeNodes {
    [CmdletBinding()] #allows making parameters mandatory and gives some added functionality for logging etc.
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Xml.XmlNode] $xml1, # old file. overwrite values here if they are different in the new one
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Xml.XmlNode] $xml2 # new file. wins value conflicts.
    )

    try {
        Trace-VstsEnteringInvocation $MyInvocation
        # merge all Attributes from xml2 into xml1
        $mergeAttributes = $xml2.Attributes
        foreach ($a in $mergeAttributes) {
            $xml1.SetAttribute($a.Name, $a.Value)
        }
        # Check for list - If either xml1 or xml2 has multiple child nodes with the same name, just take the one(s) from xml2.
        $listItems = New-Object System.Collections.Generic.List[System.Xml.XmlNode] # since lists are just replaced, no need to check list items in the later steps
        $names1 = $xml1.SelectNodes("*").Name | Select-Object -Unique # distinct node names
        foreach ($n in $names1) {
            $nodes = $xml1.SelectNodes($n) # nodes of that name
            if ($nodes.Count -gt 1) { # more than one -> list items!
                foreach($listItemNode in $nodes) {
                    $trash = $xml1.RemoveChild($listItemNode) # remove old list items
                }
                $newListItems = $xml2.SelectNodes($n)
                foreach($listItemNode in $newListItems) {
                    $trash = $listItems.Add($xml2.RemoveChild($listItemNode)) # move new list items to $listItems
                }
            }
        }
        $names2 = $xml2.SelectNodes("*").Name |Select-Object -Unique # distinct node names
        foreach ($n in $names2) {
            $nodes = $xml2.SelectNodes($n) # nodes of that name
            if ($nodes.Count -gt 1) { # more than one -> list items!
                $oldListItems = $xml1.SelectNodes($n)
                foreach($listItemNode in $oldListItems) {
                    $trash = $xml1.RemoveChild($listItemNode) # remove old list items
                }
                foreach($listItemNode in $nodes) {
                    $trash = $listItems.Add($xml2.RemoveChild($listItemNode)) # move new list items to $listItems
                }                
            }
        }

        # childnodes of xml1: check if xml2 has the same node, if so: recurse!
        # NOT for lists. If either xml1 or xml2 has multiple child nodes with the same name, just take the one(s) from xml2.
        foreach($c in $xml1.SelectNodes("*")) {
            $xml2Nodes = $xml2.SelectNodes($c.Name)
            if ($xml2Nodes.Count -eq 0) { continue }
            $c2 = $xml2Nodes[0]
            $newC = mergeNodes $c $c2
            $trash = $xml1.ReplaceChild($newC, $c)
        }
        # childnodes of xml2: check if they're in xml1 (and thus covered above), if not: add!
        foreach ($c in $xml2.SelectNodes("*")) {
            $xml1Nodes = $xml1.SelectNodes($c.Name)
            if ($xml1Nodes.Count -ne 0) { continue }
            $trash = $xml1.AppendChild($c)
        }
        # set value to value of xml2 if no further childnodes 
        if ($xml2.SelectNodes("*").Count -eq 0) {
            $xml1.InnerText = $xml2.InnerText
        }
        # add list items back in
        foreach($listItemNode in $listItems) {
            $trash = $xml1.AppendChild($listItemNode)
        }

        return $xml1
    } finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}