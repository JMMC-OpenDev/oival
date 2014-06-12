xquery version "3.0";

import module namespace app="http://jmmc.fr/apps/oival/templates" at "modules/app.xql";

declare option exist:serialize "method=html media-type=text/html";

<div xmlns="http://www.w3.org/1999/xhtml" class="templates:surround?with=templates/page.html&amp;at=content">
    {app:validate()}
</div>
(: 
    to be moved in validate.html after an upgrade to exist 2.2RC2+
    remove at the same time the special case in controller.xql
:)