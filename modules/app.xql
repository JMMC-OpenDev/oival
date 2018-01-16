xquery version "3.0";

module namespace app="http://jmmc.fr/apps/oival/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://jmmc.fr/apps/oival/config" at "config.xqm";

import module namespace jmmc-about="http://exist.jmmc.fr/jmmc-resources/about" at "/db/apps/jmmc-resources/content/jmmc-about.xql";

import module namespace jmmc-oiexplorer="http://exist.jmmc.fr/jmmc-resources/oiexplorer" at "/db/apps/jmmc-resources/content/jmmc-oiexplorer.xql";

declare function app:validate($node as node(), $model as map(*), $urls as xs:string*) {
    (app:validate())
};

declare function app:show-failures($node as node(), $model as map(*)) {
    let $failures := doc($config:app-root||"/Failures.xml")
    let $rules :=doc($config:app-root||"/DataModelV2.xml")
    return app:format-failures-report($failures, $rules)
};

declare function app:format-check-report($report as xs:string) as node()*{
  let $lines := tokenize($report, "&#10;")
  let $styles := <styles><s><t>INFO</t><c>text-info</c></s><s><t>WARNING</t><c>text-warning</c></s><s><t>SEVERE</t><c>text-danger</c></s></styles>
  let $els := for $line in $lines  
                    let $class:=for $t in $styles//t return if(starts-with(normalize-space($line), $t)) then data($styles//s[t=$t]/c) else () 
                    return <li class="{$class}">{$line}</li>
  return <ul class="list-unstyled">{$els}</ul>
};

declare function app:format-failures-report($failures as node()?, $rules as node()?) as node()*{
(:    let $profile := $failures/profile:)
    
(: with grouping :)    
(:    let $res := for $f-by-hdus in $failures//failure group by $hdu := $f-by-hdus/extName||"#"||$f-by-hdus/extNb:)
(:                    return:)
(:                        ( :)
(:                            for $f at $pos in $f-by-hdus :)
(: without grouping :) 
        let $res :=        (    for $f at $pos in $failures//failure
                                let $hdu := $f/extName||"#"||$f/extNb    
        
 


                                let $label-level := switch ($f/severity) 
                                    case "SEVERE" return "danger"
                                    case "WARNING" return "warning"
                                    case "INFO" return "info"
                                    default return "default"
                                let $rule-desc := data($rules//rule[name=$f/rule]/description)
                                
                                let $data-nb := if($f/data) then count($f/data) else "1"
                                
                                let $failure-desc := (
                                    <td rowspan="{$data-nb}"><a href="https://svn.jmmc.fr/jmmc-sw/oiTools/trunk/oitools/rules/DataModelV2_output.html#RULE_{$f/rule}" target="_blank"><span class="label label-{$label-level}">{data($f/rule)}</span></a><br/>{$rule-desc} </td>,
                                    <td rowspan="{$data-nb}">{data($hdu)}</td>,
                                    <td rowspan="{$data-nb}">{data($f/member)}</td>
                                )
                                
                                return 
                                    if ($f/data)
                                    then
                                        for $d at $pos in $f/data return 
                                            <tr>
                                                {if ($pos=1) then $failure-desc else () }
                                                <td>{replace($d/message,"\|", ", ")}</td>
                                                <td>{data($d/row)}</td>
                                                <td>{data($d/col)}</td>
                                                <td>{data($d/value)}</td>
                                                <!-- <td><ul>{for $e in tokenize($d/expected,"\|") return <li>{$e}</li>}</ul></td>-->
                                                <td>{replace($d/expected,"\|", ", ")}</td>
                                                <td>{data($d/limit)}</td>
                                                <td>{data($d/detail)}</td>
                                            </tr>
                                    else 
                                        <tr>{($failure-desc)}<td colspan="7">{data($f/message)}</td></tr>
                                
                        )
    return 
        <div class="table-responsive">
            <table class="table table-bordered table-condensed table-hover">
                <thead>
                    <tr>
                        <th rowspan="2">Rule </th>
                        <th rowspan="2">HDU </th>
                        <th rowspan="2">Member </th>
                        <th colspan="7">Data</th>
                    </tr>
                    <tr>
                        <th>Message </th><th>Row </th><th>Col </th><th>Value </th><th>Expected </th><th>Limit </th><th>Detail </th>
                    </tr>
                </thead>
                <tbody>
                    {
                       $res
                    }
                </tbody>
            </table>
        </div>
};


(: 
   TODO add xqldoc, and split code in multiple functions
 :)
declare function app:show-html($xml as node()*) {
    for $oifits in $xml//oifits (: there should be only one oifits :)
        let $uuid := util:uuid()
        let $filename := tokenize($xml/url||$xml/filename,"/")[last()]
        let $oitables := $xml//oifits/*[starts-with(name(.),"OI_")]
        let $prim-hdu-keywords := $oifits/keywords/keyword
        let $check-report := $xml//checkReport
        let $chech-report-severity := if(matches($check-report, "SEVERE")) then "danger" else if(matches($check-report, "WARNING")) then "warning" else ()
        let $failures := $xml//failures
        let $rules := $xml//rules

        
        
        return
            <div class="panel panel-default" id="oifits{$uuid}">
                <div class="panel-heading">
                    <h3 class="panel-title">
                        <b>{$xml/url||$xml/filename}</b>
                    </h3>
                </div>
                <div class="panel-body">
                <!-- Nav bar -->
                <nav  class="navbar navbar-default navbar-static" role="navigation">
                    <ul class="nav navbar-nav">
                    <li><p class="navbar-text"><b>{$xml/url||$xml/filename}</b></p></li>
                    <li><a href="#granules{$uuid}">Granules ({count($xml//metadata//target)})</a></li>
                    { if ($prim-hdu-keywords) then <li><a href="#prim-hdu-keywords-{$uuid}">Primary HDU keywords ({count($prim-hdu-keywords)})</a></li> else () }
                    <li ><a href="#report{$uuid}">Check report&#160;{if($chech-report-severity) then <i class="glyphicon glyphicon-warning-sign"/> else ()}</a></li>
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
                  <li>&#160;</li>
                </ul>
                </nav>
                <div>
                        <ol id="granules{$uuid}" class="breadcrumb">
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
                        
                        <ol id="report{$uuid}" class="breadcrumb">
                          <li><a href="#top">TOP^</a></li>
                          <li><a href="#oifits{$uuid}">OIFits</a></li>
                          <li class="active">Check report</li>
                        </ol>
                        {app:format-check-report($check-report)}
                        <hr/>
                        {app:format-failures-report($failures, $rules)}
                        
                        { if ( $prim-hdu-keywords ) then
                        (<ol id="prim-hdu-keywords-{$uuid}" class="breadcrumb">
                          <li><a href="#top">TOP^</a></li>
                          <li><a href="#oifits{$uuid}">OIFits</a></li>
                          <li class="active">Primary HDU keywords</li>
                        </ol>,
                        <p> 
                            <button data-toggle="modal" data-target="#hdu-keywords-{$uuid}">Display primary HDU keywords ({count($prim-hdu-keywords)})</button>
                            <!-- Modal view for primary HDU keywords -->
                            <div class="modal fade" id="hdu-keywords-{$uuid}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
                              <div class="col-xs-11 center-block"> <!-- would prefer something like modal-dialog modal-10 but... -->
                                <div class="modal-content">
                                  <div class="modal-header">
                                    <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">X</span><span class="sr-only">Close</span></button>
                                    <h4 class="modal-title" id="myModalLabel">Primary HDU keywords for <b>{$filename}</b></h4>
                                  </div>
                                  <div class="modal-body">
                                  <table class="table table-bordered table-condensed table-hover">
                                  {
                                    for $k in $prim-hdu-keywords
                                    return <tr><th>{$k/name/text()}</th><td>{$k/value/text()}</td><td><i title="{$k/description/text()}" class="glyphicon glyphicon-question-sign"/></td></tr>
                                  }
                                  </table>
                                  </div>
                                  <div class="modal-footer">
                                    <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                                  </div>
                                </div>
                              </div>
                            </div>                            
                        </p>)
                        else <p>No primary HDU keywords</p>
                        }
                        
                        <ol id="tables{$uuid}" class="breadcrumb">
                          <li><a href="#top">TOP^</a></li>
                          <li><a href="#oifits{$uuid}">OIFits</a></li>
                          <li class="active">OI_Tables</li>
                        </ol>
                        <p> This file gets {count($oitables)} OI tables:
                            <ul class="list-inline">{
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
                                <div class="panel panel-default" id="{$anchor}">
                                    <ol class="breadcrumb">
                                      <li><a href="#top">TOP^</a></li>
                                      <li><a href="#oifits{$uuid}">OIFits</a></li>
                                      <li><a href="#tables{$uuid}">Tables</a></li>
                                      <li class="active">{$label} ({data($oidata/rows)} rows)</li>
                                    </ol>
                                    <h4>Keywords</h4>
                                    <table class="table table-bordered table-condensed table-hover"><tr>{
                                    for $t in $oidata/keywords/keyword[1]/* return <th>{name($t)}</th>
                                    }</tr>{
                                        for $k in $oidata/keywords/keyword return <tr> {for $e in $k/* return <td>{data($e)}</td>}</tr>
                                    }</table>
                            
                                    {
                                    if(name($oidata)=("OI_TARGET","OI_ARRAY","OI_WAVELENGTH"))
                                    then
                                        (<h4>Table data</h4>
                                        ,<table class="table table-bordered table-condensed table-hover"><tr>{
                                            for $c in $oidata/columns/column 
                                                let $unit := tokenize($c/unit,"\|")
                                                let $unit := if(exists($unit)) then concat(" [",$unit[last()],"]") else ()
                                                return 
                                                <th><a title="{$c/description}">{data($c/name)} {$unit}</a></th>
                                            }</tr>
                                            {
                                               $oidata/table/tr[td]
                                            }
                                        </table>)
                                    else ()
                                    }
                                </div>
                        }
                    
                </div>
            </div>
        </div>
};

(: To be refactored using template when validate.html will be ready :)
declare function app:validate() {  
    (: read input params :)
    let $urls := request:get-parameter("urls", ())
    let $url-list := distinct-values( for $u in $urls return tokenize($u, "[,\s]+") )
    let $upload-filename := request:get-uploaded-file-name("userfile")
    
    (: build one record per oifits source:)
    let $ret1 := for $u in $url-list return <record><url>{$u}</url>{ try { jmmc-oiexplorer:to-xml($u) } catch * { <error>{$err:description}</error> } }</record>
    let $ret2 := if($upload-filename) then <record><filename>{$upload-filename}</filename>{ try { jmmc-oiexplorer:to-xml(request:get-uploaded-file-data("userfile"))  } catch * {<error>{$err:description}</error> }}</record> else ()
    let $ret := ($ret1,$ret2)
    
    (: transform each record into html :)
    let $records := <records>{for $e in $ret return app:show-html($e)}</records>
    
    (: and summarize the whole results after a display of the errors :)
    let $res := <div >
        {
            for $e in $ret[error] 
                let $filename := tokenize($e/url||$e/filename,"/")[last()]
            return
                <div class="alert alert-danger alert-dismissable fade in">
                    <i class="icon icon-times-circle icon-lg"></i>
                    <strong>{$filename}</strong> : {data($e/error)}
                </div>
                
            ,
            if (count($records//nav)>1) then
                <div class="col-md-12">
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
                            <ul class="list-inline">
                                {$records//nav}
                            </ul>
                        </li>
                    </ul>
                </div>
                else 
                ()
        }
        <div class="col-md-12">{ $records/div }</div>
    </div>
    
    return $res
};
