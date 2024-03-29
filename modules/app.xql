xquery version "3.0";

module namespace app="http://jmmc.fr/apps/oival/templates";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";
import module namespace config="http://jmmc.fr/apps/oival/config" at "config.xqm";

import module namespace jmmc-about="http://exist.jmmc.fr/jmmc-resources/about" at "/db/apps/jmmc-resources/content/jmmc-about.xql";

import module namespace jmmc-oiexplorer="http://exist.jmmc.fr/jmmc-resources/oiexplorer" at "/db/apps/jmmc-resources/content/jmmc-oiexplorer.xql";

import module namespace jmmc-vizier="http://exist.jmmc.fr/jmmc-resources/vizier" at "/db/apps/jmmc-resources/content/jmmc-vizier.xql";
import module namespace jmmc-simbad="http://exist.jmmc.fr/jmmc-resources/simbad" at "/db/apps/jmmc-resources/content/jmmc-simbad.xql";


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
                                    <td rowspan="{$data-nb}"><a href="https://jmmc-opendev.github.io/oitools/rules/DataModelV2_output.html#RULE_{$f/rule}" target="_blank"><span class="label label-{$label-level} severity-{$label-level} ">{data($f/rule)}</span></a><br/>{$rule-desc} </td>,
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
            <p> Severity legend:
                {
                for $severity in distinct-values($failures//failure/severity)
                                let $label-level := switch ($severity)
                                    case "SEVERE" return "danger"
                                    case "WARNING" return "warning"
                                    case "INFO" return "info"
                                    default return "default"
                                    return <span class="label label-{$label-level}">{$severity}</span>
                }
            </p>
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


declare function app:show-provenance($prim-hdu-keywords,$filename ){
    <div>
        <h2>Data reduction information extracted from the headers:</h2>
            {
            let $kws := $prim-hdu-keywords[starts-with(name,"HIERARCH.ESO.PRO.REC")]

            let $rec-prefix := "HIERARCH.ESO.PRO.REC"
            let $rec-prefix-len := string-length($rec-prefix)
            let $rec-kws := $kws[starts-with(name, $rec-prefix)]
            let $dls := map{
                "PROCSOFT" : data($prim-hdu-keywords[name = "PROCSOFT"]/value),
                "DRS ID": string-join(distinct-values($rec-kws[ends-with(name,".DRS.ID")]/value), ", ") ,
                "PIPELINE ID": string-join(distinct-values($rec-kws[ends-with(name,".PIPE.ID")]/value), ", ")
            }

            return <dl>{
                 map:for-each( $dls, function ($k, $v){ if(exists($v) and string-length($v)>0 ) then (<dt>{$k}</dt>,<dd>{$v}</dd>) else () })
                , if( empty($rec-kws) ) then () else
                (<dt>HIERARCH ESO RECipies:</dt>,<dd>
                <ul>{
                for $kw in $rec-kws  group by $step := substring-before(substring-after($kw,$rec-prefix),".")
                    (:prepare prefixes :)
                    let $step-prefix := $rec-prefix||$step (: e.g.: HIERARCH.ESO.PRO.REC1 :)
                    let $raw-prefix := $step-prefix|| ".RAW"
                    let $cal-prefix := $step-prefix|| ".CAL"
                    let $param-prefix := $step-prefix|| ".PARAM"

                    (: first step kw filter :)
                    let $step-kws := $kws[starts-with(name,$step-prefix)]

                    (: get rec-id :)
                    let $rec-id := $step-kws[name=$step-prefix||".ID"]

                    (: get params :)
                    let $step-params := $step-kws[starts-with(name, $param-prefix)]
                    let $step-params-names := $step-params[ends-with(name, ".NAME")]

                    (: get raws :)
                    let $step-files := $step-kws[starts-with(name, $raw-prefix) or starts-with(name, $cal-prefix)]
                    let $file-names := $step-files[ends-with(name, "NAME")]
                    let $file-catgs := $step-files[ends-with(name, "CATG")]


                    (: we may study other more efficient analysis approaches to avoid multiple whole scan per category
                    e.g. :
                    let $els := for $kw in $step-kw
                        return
                            if(name=$step-prefix||".ID") then <rec>{$kw}</rec>
                            if(contains(name, ".PARAM")) then <param>{$kw}</param>
                    OR rebuild a tree with HIERARCH/ESO/PRO/[REC1,...,RECN]/ or map of RECS:{1:RAW:1,...N,...,N:{}}
                    :)

                    return
                        <li><ul class="list-inline">
                        <b>{ $rec-id/value/text() }&#160;</b>
                        { for $n in $step-params-names
                            let $v := $step-params[name=substring-before($n,".NAME")||".VALUE"]
                            let $v := if($v) then <var>{normalize-space($v/value)}</var> else ()
                            let $pname := <b>&#160;--{normalize-space($n/value)}</b>
                            let $pname := if(exists($v)) then ($pname,"=") else $pname
                            return
                            <li>{$pname,$v}</li>
                        }&#160;
                        {
                          for $n at $pos in $file-names group by $catg := data($file-catgs[$pos]/value)
                            return <li><b>{$catg}</b>=[<var>{string-join($n/value,", ")}</var>]</li>
                        }
                        </ul></li>

                }</ul></dd>)
            }</dl>}
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
        let $prim-hdu-keywords := $oifits/hdu/keywords/keyword
        let $check-report := $xml//checkReport
        let $chech-report-severity := if(matches($check-report, "SEVERE")) then "danger" else if(matches($check-report, "WARNING")) then "warning" else ()
        let $failures := $xml//failures
        let $rules := $xml//rules

        return
            <div class="panel panel-default" data-report="" id="oifits{$uuid}">
                <div class="panel-heading">
                    <h3 class="panel-title">
                        <b>{$xml/url||$xml/filename}</b>
                    </h3>
                </div>
                <div class="panel-body">
                <!-- Nav bar to provide acce on data content -->
                <nav  class="navbar navbar-default navbar-static" role="navigation">
                    <ul class="nav navbar-nav">
                    <li><p class="navbar-text" data-filename=""><b>{$xml/url||$xml/filename}</b></p></li><!-- data-filename put for futur retrieval -->
                    <li><a href="#granules{$uuid}">Granules ({count($xml//metadata//target)})</a></li>
                    <li ><a href="#report{$uuid}">Check report&#160;{if($chech-report-severity) then <i class="glyphicon glyphicon-warning-sign"/> else ()}</a></li>
                    { if ($prim-hdu-keywords) then <li><a href="#prim-hdu-keywords-{$uuid}">Primary HDU keywords ({count($prim-hdu-keywords)})</a></li> else () }
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
                    <li><p class="navbar-text">OIFITS V{substring($oifits/version,9)}</p></li>
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
                                        let $ra := $t/s_ra
                                        let $dec := $t/s_dec
                                        let $name := data($t/target_name)
                                        let $by-name := jmmc-simbad:resolve-by-name($name, $ra, $dec)
                                        let $by-coords := if(exists($by-name)) then () else jmmc-simbad:resolve-by-coords($ra, $dec, 0.01)
                                        let $by-coords := if($by-coords) then
                                            (<span>Could be one of : </span>,<ul>
                                                { for $target in $by-coords
                                                    return <li><b>{data($target/name)}</b> <ul class="list-unstyled"><li>{string-join((for $e in ($target/ra,$target/dec) return round-half-to-even($e,3)), " ")}</li><li>{"dist="||round-half-to-even($target/dist,4)}</li></ul></li>
                                                }
                                            </ul>)
                                            else ()
                                        let $title := if($by-name) then <span class="text-success">Valid identifier</span> else <span class="text-danger"><i class="glyphicon glyphicon-warning-sign"/> Invalid identifier : unknown by Simbad {$by-coords}</span>[empty($by-name)]
                                        let $title := serialize($title)
                                        let $icon := if($by-name) then "text-success glyphicon glyphicon-ok-sign" else "text-danger glyphicon glyphicon-exclamation-sign"
                                        return <td><a href="#" rel="tooltip" data-html="true" data-original-title="{$title}"> <i class="{$icon}"/></a> &#160; {$name}</td>
                                        ,
                                                for $e in $t/*[name(.)[not(.='target_name'or starts-with(.,"nb_"))]] return <td>{data($e)}</td>
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

                        { if (empty($failures//failure)) then () else
                        <div class="panel-group">
                          <div class="panel panel-default">
                            <div class="panel-heading">
                              <h4 class="panel-title">
                                <a data-toggle="collapse" href="#faildetails{$uuid}">Details on failures... </a>
                              </h4>
                            </div>
                            <div id="faildetails{$uuid}" class="panel-collapse collapse">
                              <div class="panel-body"  data-faildetails=""><!-- data-faildetails put for future retrieval -->{app:format-failures-report($failures, $rules)}</div>
                            </div>
                          </div>
                        </div>
                        }

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
                            {app:show-provenance($prim-hdu-keywords, $filename)}
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
                                                let $trs := $oidata/table/tr[td]
                                                let $count := count($trs)
                                                let $cut := 5
                                                return
                                                    if ($count<=2*$cut) then
                                                        $trs
                                                    else
                                                        let $first-trs := subsequence($trs, 1, $cut)
                                                        let $last-trs := subsequence($trs, $count - $cut, $cut)
                                                        let $dots := <tr>{for $td in $trs[1]/td return <td>...</td>}</tr>
                                                        return
                                                            ($first-trs, $dots, $last-trs)
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

declare function app:validate($node as node(), $model as map(*), $urls as xs:string*) {
    (app:validate())
};

(: To be refactored using template when validate.html will be ready :)
declare function app:validate() {
    (: read input params :)
    let $urls := request:get-parameter("urls", ())
    let $url-list := distinct-values( for $u in $urls return tokenize($u, "[,\s]+") )
    let $upload-filename := request:get-uploaded-file-name("userfile")
    let $cat := request:get-parameter("cat", ())

    (: build one record per oifits source:)
    let $ret1 := for $u in $url-list return <record><url>{$u}</url>{ try { jmmc-oiexplorer:to-xml($u) } catch * { <error>{$err:description}</error> } }</record>
    let $ret2 := if($upload-filename) then <record><filename>{$upload-filename}</filename>{ try { jmmc-oiexplorer:to-xml(request:get-uploaded-file-data("userfile"))  } catch * {<error>{$err:description}</error> }}</record> else ()

    let $ret3 := if($cat) then
        try{
            let $urls := jmmc-vizier:catalog-fits($cat)
            for $url in $urls return <record><cat>{$cat}</cat><url>{$url}</url>{ try { jmmc-oiexplorer:to-xml($url) } catch * { <error>CAT {$cat} {$err:description}</error> } }</record>
        } catch * {
            <record><cat>{$cat}</cat><error>VizieR catalog {$cat} not found&#10;<br/> {$err:description}</error> </record>
        }
        else ()
    let $ret := ($ret1,$ret2,$ret3)

    (: transform each record into html :)
    let $records := <records>{for $e in $ret return app:show-html($e)}</records>

    (: and summarize the whole results after a display of the errors :)
    let $res := <div >
        {
            for $e in $ret[error]
                let $filename := tokenize($e/url||$e/filename,"/")[last()] || $e/cat
            return
                <div class="alert alert-danger alert-dismissable fade in">
                    <i class="icon icon-times-circle icon-lg"></i>
                    <strong>{$filename}</strong> : {data($e/error)}
                </div>

            ,
            if (count($records//nav)>1) then
                <div class="col-md-12">
                    <ul class="nav">

                        <li><a href="#checkreportsummary">CheckReport summary</a>
                        <ul>
                        {
                            for $spans in $records//span[contains(@class, "severity")] group by $type:=$spans
                                return  <li>{$spans[1]} : {count($spans)}</li>
                        }</ul>
                        </li>
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
        { if (exists($records//div[@data-faildetails])) then
            <div class="col-md-12">
                <h3 id="checkreportsummary">CheckReport summary</h3>
                {
                    for $record in $records//div[@data-report][.//div[@data-faildetails]]
                    return
                        (<h4>{data($record//p[@data-filename])}</h4>, $record//div[@data-faildetails])
                }
            </div>
        else () }
    </div>

    return $res
};
