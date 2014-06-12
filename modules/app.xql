xquery version "3.0";

module namespace app="http://jmmc.fr/apps/oival/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://jmmc.fr/apps/oival/config" at "config.xqm";

import module namespace jmmc-about="http://exist.jmmc.fr/jmmc-resources/about" at "/db/apps/jmmc-resources/content/jmmc-about.xql";

import module namespace jmmc-oiexplorer="http://exist.jmmc.fr/jmmc-resources/oiexplorer" at "/db/apps/jmmc-resources/content/jmmc-oiexplorer.xql";

(: 
 to uncomment when validate.html will be ready
 declare function app:validate($node as node(), $model as map(*), $urls as xs:string*) {
    (app:validate())
};
:)

(: 
   TODO add xqldoc, and split code in multiple functions
 :)
declare function app:show-html($xml as node()*) {
    let $uuid := util:uuid()
    return for $oifits in $xml//oifits
        let $filename := tokenize($xml/url||$xml/filename,"/")[last()]
        let $oitables := $xml//oifits/*[starts-with(name(.),"OI_")] 
        return
            (<ul>
                <li><a href="#oifits{$uuid}">{$filename}</a>
                <ul>
                    <li><a href="#granules{$uuid}">Granules ({count($xml//metadata//target)})</a></li>
                    <li><a href="#report{$uuid}">Validation Report</a></li>
                    <li><a href="#tables{$uuid}">OI_Tables ({count($oitables)})</a></li>
                </ul>
                </li>
            </ul>,
            <div>
                <a name="oifits{$uuid}"/>
                {$xml/url||$xml/filename}
                <!-- Nav bar -->
                <nav  class="navbar navbar-default navbar-static" role="navigation">
                    <ul class="nav navbar-nav">
                    <li><a href="#granules{$uuid}">Granules ({count($xml//metadata//target)})</a></li>
                    <li ><a href="#report{$uuid}">Check report</a></li>
                    <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">OI_Tables ({count($oitables)}) <b class="caret"></b></a>
                        <ul class="dropdown-menu">
                         {
                         for $oidata at $pos in $oitables
                            let $label := "#"||$pos||" "||name($oidata)
                            let $anchor := "table_"||$pos||"_"||$uuid
                            return <li><a href="#{$anchor}">{$label}</a></li>
                        }
                      </ul>
                    </li>
                  <li></li>
                </ul>
                </nav>
                
                <div>
                        <ol id="granules{$uuid}"class="breadcrumb">
                                              <li><a href="#top">TOP^</a></li>
                                              <li><a href="#oifits{$uuid}">OIFits</a></li>
                                              <li class="active">Granules</li>
                                            </ol>
                        {
                            for $meta in $xml//metadata
                            return <table class="table table-bordered table-condensed table-hover">
                                    <tr>{for $t in $meta//target[1]/*[not(starts-with(name(.),"nb_"))] return <th>{name($t)}</th>}</tr>
                                    {
                                    for $t in $meta//target return 
                                        <tr>{
                                                for $e in $t/*[not(starts-with(name(.),"nb_"))] return <td>{data($e)}</td>
                                        }</tr>
                                    }
                            </table>
                        }
                        <ol class="breadcrumb">
                                              <li><a href="#top">TOP^</a></li>
                                              <li><a href="#oifits{$uuid}">OIFits</a></li>
                                              <li class="active">Check report</li>
                                            </ol>
                                    
                        <pre id="report{$uuid}">{data($xml//checkReport)}</pre>
                        
                        <ol id="tables{$uuid}" class="breadcrumb">
                                              <li><a href="#top">TOP^</a></li>
                                              <li><a href="#oifits{$uuid}">OIFits</a></li>
                                              <li class="active">OI_Tables</li>
                                            </ol>
                        <p> This file gets {count($oitables)} OI tables:
                            <ul>{
                                for $oidata at $pos in $oitables
                                let $label := "#"||$pos||" "||name($oidata)
                                let $anchor := "table_"||$pos||"_"||$uuid
                                return <li><a href="#{$anchor}">{$label}</a></li>
                            }</ul>
                        </p>
                        {
                            for $oidata at $pos in $oitables
                            let $label := "#"||$pos||" "||name($oidata)
                            let $anchor := "table_"||$pos||"_"||$uuid
                            return 
                                <div id="{$anchor}">
                                    <ol class="breadcrumb">
                                              <li><a href="#top">TOP^</a></li>
                                              <li><a href="#oifits{$uuid}">OIFits</a></li>
                                              <li><a href="#tables{$uuid}">Tables</a></li>
                                              <li class="active">{$label}</li>
                                            </ol>
                                    <p> This table gets {data($oidata/rows)} rows.</p>         
                                    <ol class="breadcrumb">
                                              <li><a href="#top">TOP^</a></li>
                                              <li><a href="#oifits{$uuid}">OIFits</a></li>
                                              <li><a href="#tables{$uuid}">Tables</a></li>
                                              <li><a href="#{$anchor}">{$label}</a></li>
                                              <li class="active">Keywords</li>
                                            </ol>
                                    <table class="table table-bordered table-condensed table-hover"><tr>{
                                        for $t in $oidata/keywords/keyword[1]/* return <th>{name($t)}</th>
                                    }</tr>
                                    {
                                        for $k in $oidata/keywords/keyword return <tr> {for $e in $k/* return <td>{data($e)}</td>}</tr>
                                    }</table>
                                    {
                                        if(name($oidata)=("OI_TARGET","OI_ARRAY","OI_WAVELENGTH"))
                                        then
                                            (<ol class="breadcrumb">
                                              <li><a href="#top">TOP^</a></li>
                                              <li><a href="#oifits{$uuid}">OIFits</a></li>
                                              <li><a href="#tables{$uuid}">Tables</a></li>
                                              <li><a href="#{$anchor}">{$label}</a></li>
                                              <li class="active">Table data</li>
                                            </ol>
                                            ,
                                            <table class="table table-bordered table-condensed table-hover"><tr>{
                                                for $c in $oidata/columns/column 
                                                    let $unit := tokenize($c/unit,"\|")
                                                    let $unit := if(exists($unit)) then concat("[",$unit[last()],"]") else ()
                                                    return 
                                                    <th><a title="{$c/description}">{data($c/name)} {$unit}</a></th>
                                            }</tr>
                                            {
                                               $oidata/table/tr[td]
                                            }</table>)
                                        else ()
                                    }
                                    
                                </div>
                        }
                    
                </div>
        </div>)

};

(: To be refactored using template when validate.html will be ready :)
declare function app:validate() {  
    
    let $urls := request:get-parameter("urls", ())
    let $url-list := for $u in $urls return tokenize($u, "[,\s]+")
    let $ret1 := for $u in $url-list 
    return <record><url>{$u}</url>
    {jmmc-oiexplorer:to-xml($u)}
    </record>
    
    let $upload-filename := request:get-uploaded-file-name("userfile")
    let $ret2 := if($upload-filename) then 
        <record>
            <filename>{$upload-filename}</filename>
            {jmmc-oiexplorer:to-xml-base64(request:get-uploaded-file-data("userfile"))}
        </record>
        else ()
    
    let $ret := ($ret1,$ret2)
    let $records := <records>{   
                    for $e in $ret return app:show-html($e)
                }</records>
    
    let $res := <div >
    <div class="col-md-12" id="top">
        <ul class="nav">
            <li>Targets
                <ul>
                    {
                        for $target in distinct-values($ret//target_name)
                            return <li>{data($target)}</li>
                    }
                </ul>
            </li>
            <li>OIfits files
            { for $e in $records/ul return $e/li }
            </li>
            
        </ul>
    </div>
    <div class="col-md-12">
        <ul class="list-group">
            { 
                for $e in $records/div
                return <li class="list-group-item">{$e}</li>
            }
        </ul>
    </div>
    </div>
    
    return $res
};
