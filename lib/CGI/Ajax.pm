package CGI::Ajax;
use strict;
use base qw(Class::Accessor);
use overload '""' => 'show_javascript'; # for building web pages, so
                                        # you can just say: print $pjx
BEGIN {
    use vars qw ($VERSION @ISA);
    $VERSION     = .68;
    @ISA         = qw(Class::Accessor);
}

########################################### main pod documentation begin ##


=head1 NAME

CGI::Ajax - a perl-specific system for writing AJAX- or DHTML-based
web applications (formerly known as the module CGI::Perljax).

=head1 SYNOPSIS

  use strict;
  use CGI;      # or any other CGI:: form handler/decoder
  use CGI::Ajax;

  my $cgi = new CGI;
  my $pjx = new CGI::Ajax( 'exported_func' => \&perl_func );

  print $pjx->build_html( $cgi, \&Show_HTML);

  sub perl_func {
    my $input = shift;
    # do something with $input
    my $output = $input . " was the input!";
    return( $output );
  }

  sub Show_HTML {
    my $html = <<EOHTML;
    <HTML>
    <BODY>
      Enter something: 
        <input type="text" name="val1" id="val1"
         onkeyup="exported_func( ['val1'], ['resultdiv'] );">
      <br>
      <div id="resultdiv"></div>
    </BODY>
    </HTML>
  EOHTML
    return $html;
  }

I<There are several fully-functional examples in the 'scripts/'
directory of the distribution.>

=head1 DESCRIPTION

CGI::Ajax is an object-oriented module that provides a unique
mechanism for using perl code asynchronously from javascript-
enhanced web pages.  You would commonly use CGI::Ajax in
AJAX/DHTML-based web applications.  CGI::Ajax unburdens the user
from having to write extensive javascript, except for associating
an exported method with a document-defined event (such as onClick,
onKeyUp, etc). Only in the more advanced implementations of an
exported perl method would a user need to write any javascript.

CGI::Ajax supports methods that return single results, or multiple
results to the web page, and supports returning values to multiple
DIV elements on the HTML page.

Using CGI::Ajax, the URL for the HTTP GET request is automatically
generated based on HTML layout and events, and the page is then
dynamically updated.  We also have support for mapping URL's to a
CGI::Ajax function name, so you can separate your code processing
over multiple scripts.

Other than using the Class::Accessor module to generate CGI::Ajax'
accessor methods, CGI::Ajax is completely self-contained -
it does not require you to install a larger package or a full
Content Management System, etc.

We have added I<support> for other CGI handler/decoder modules,
like L<CGI::Simple> or L<CGI::Minimal>, but we can't test these
since we run mod_perl2 only here.  CGI::Ajax checks to see if a
header() method is available to the CGI object, and then uses it.
If method() isn't available, it creates it's own minimal header.

A primary goal of CGI::Ajax is to keep the module streamlined and
maximally flexible.  We are trying to keep the generated javascript
code to a minimum, but still provide users with a variety of
methods for deploying CGI::Ajax. And VERY little user javascript.

=head1 EXAMPLES

The CGI::Ajax module allows a Perl subroutine to be called
asynchronously.  To do this, it must be I<exported>:

  my $pjx = new CGI::Ajax( 'JSFUNC' => \&PERLFUNC );

This maps a perl subroutine (PERLFUNC) to an automatically
generated Javascript function (JSFUNC).  Next you setup an HTML
event to call the new Javascript function:

  onClick="JSFUNC(['source1','source2'], ['dest1','dest2']);"

where 'source1', 'dest1', 'source2', 'dest2' are the DIV ids of
HTML elements in your page...

  <input type=text id=source1>

L<CGI::Ajax> sends the values from source1 and source2 to your
Perl subroutine and returns the results to dest1 and dest2.

=head2 4 Usage Methods

=over 4

=item 1 Standard CGI::Ajax example

Start by defining a perl subroutine that you want available from
javascript.  In this case we'll define a subrouting that determines
whether or not an input is odd, even, or not a number (NaN):

  use strict;
  use CGI::Ajax;
  use CGI;


  sub evenodd_func {
    my $input = shift;

    # see if input is defined
    if ( not defined $input ) {
      return("input not defined or NaN");
    }

    # see if value is a number (*thanks Randall!*)
    if ( $input !~ /\A\d+\z/ ) {
      return("input is NaN");
    }

    # got a number, so mod by 2
    $input % 2 == 0 ? return("EVEN") : return("ODD");
  }

Alternatively, we could have used coderefs to associate an
exported name...

  my $evenodd_func = sub {
    # exactly the same as in the above subroutine
  };

Next we define a function to generate the web page - this can
be done many different ways, and can also be defined as an
anonymous sub.  The only requirement is that the sub send back
the html of the page.  You can do this via a string containing the
html, or from a coderef that returns the html, or from a function
(as shown here)...

  sub Show_HTML {
    my $html = <<EOT;
  <HTML>
  <HEAD><title>CGI::Ajax Example</title>
  </HEAD>
  <BODY>
    Enter a number:&nbsp;
    <input type="text" name="somename" id="val1" size="6"
       onkeyup="evenodd( ['val1'], ['resultdiv'] );">
    <br>
    <hr>
    <div id="resultdiv">
    </div>
  </BODY>
  </HTML>
EOT
    return $html;
  }

Note how we reference the exported subroutine in the C<OnKeyup>
event handler.  The subroutine takes one value from the form,
the element B<'val1'>, and returns the the result to an HTML
div element with an id of B<'resultdiv'>.  Sending in the input
id in an array format is required to support multiple inputs,
and similarly, to output multiple the results, you can use an
array for the output divs, but this isn't mandatory - as will be
explained in the B<Advanced> usage.

Now create a CGI object...

  my $cgi = new CGI();

And finally we create a CGI::Ajax object, associating a reference
to our subroutine with the name we want available to javascript.

  my $pjx = new CGI::Ajax( 'evenodd' => \&evenodd_func );

And if we used a coderef, it would look like this...

  my $pjx = new CGI::Ajax( 'evenodd' => $evenodd_func );

Now we're ready to print the output page; we send in the cgi
object and the HTML-generating function.

  print $pjx->build_html($cgi,\&Show_HTML);

CGI::Ajax has support for passing in extra HTML header information
to the CGI object.  This can be accomplished by adding a third
argument to the build_html() call.  The argument needs to be a
hashref containing Key=>value pairs that CGI objects understand:

  print $pjx->build_html($cgi,\&Show_HTML,
    {-charset=>'UTF-8, -expires=>'-1d'});

See L<CGI> for more header() method options.

That's it for the CGI::Ajax standard method.  Let's look at
something more advanced.

=item 2 Advanced CGI::Ajax example

Let's say we wanted to have a perl subroutine process multiple
values from the HTML page, and similarly return multiple values
back to distinct divs on the page.  This is easy to do, and
requires no changes to the perl code - you just create it as you
would any perl subroutine that works with multiple input values
and returns multiple values.  The significant change happens in
the event handler javascript in the HTML...

  onClick="exported_func(['input1','input2'],['result1','result2']);"

Here we associate our javascript function ("exported_func") with
two HTML element ids ('input1','input2'), and also send in two
HTML element ids to place the results in ('result1','result2').

=item 3 Sending Perl Subroutine Output to a Javascript function

Occassionally, you might want to have a custom javascript function
process the returned information from your Perl subroutine.
This is possible, and the only requierment is that you change
your event handler code...

  onClick="exported_func(['input1'],[js_process_func]);"

In this scenario, C<js_process_func> is a javascript function you
write to take the returned value from your Perl subroutine and
process the results.  I<Note that a javascript function is not
quoted -- if it were, then CGI::Ajax would look for a HTML element
with that id.>  Beware that with this usage, B<you are responsible
for distributing the results to the appropriate place on the
HTML page>.  If the exported Perl subroutine returns, e.g. 2
values, then C<js_process_func> would need to process the input
by working through an array, or using the javascript Function
C<arguments> object.

  function js_process_func() {
    var input1 = arguments[0]
    var input2 = arguments[1];
    // do something and return results, or set HTML divs using
    // innerHTML
    document.getElementById('outputdiv').innerHTML = input1;
  }

=item 4 URL/Outside Script CGI::Ajax example

There are times when you may want a different script to
return content to your page.  This could be because you have
an existing script already written to perform a particular
task, or you want to distribute a part of your application to another
script.  This can be accomplished in L<CGI::Ajax> by using a URL in
place of a locally-defined Perl subroutine.  In this usage,
you alter you creation of the L<CGI::Ajax> object to link an
exported javascript function name to a local URL instead of
a coderef or a subroutine.

  my $url = 'scripts/other_script.pl';
  my $pjx = new CGI::Ajax( 'external' => $url );

This will work as before in terms of how it is called from you
event handler:

  onClick="external(['input1','input2'],['resultdiv']);"

The other_script.pl will get the values via a CGI object and
accessing the 'args' key.  The values of the B<'args'> key will
be an array of everything that was sent into the script.

  my @input = $cgi->params('args');
  $input[0]; # contains first argument
  $input[1]; # contains second argument, etc...

This is good, but what if you need to send in arguments to the
other script which are directly from the calling Perl script,
i.e. you want a calling Perl script's variable to be sent, not
the value from an HTML element on the page?  This is possible
using the following syntax:

  onClick="exported_func(['args__$input1','args__$input2'],
                         ['resultdiv']);"

Similary, if the external script required a constant as input
(e.g.  C<script.pl?args=42>, you would use this syntax:

  onClick="exported_func(['args__42'],['resultdiv']);"

In both of the above examples, the result from the external
script would get placed into the I<resultdiv> element on our
(the calling script's) page.

In order to rename parameters, in case the outside script needs
specifically-named parameters and not CGI::Ajax' I<'args'> default
parameter name, change your event handler associated with an HTML
event like this

  onClick="exported_func(['myname__$input1','myparam__$input2'],
                         ['resultdiv']);"

The URL generated would look like this...

C<script.pl?myname=input1&myparam=input2>

You would then retrieve the input in the outside script with this...

  my $p1 = $cgi->params('myname');
  my $p1 = $cgi->params('myparam');

Finally, what if we need to get a value from our HTML page and we
want to send that value to an outside script but the outside script
requires a named parameter different from I<'args'>?  You can
accomplish this with L<CGI::Ajax> using the getVal() javascript
method (which returns an array, thus the C<getVal()[0]> notation):

  onClick="exported_func(['myparam__' + getVal('div_id')[0]],
                         ['resultdiv']);"

This will get the value of our HTML element with and
I<id> of I<div_id>, and submit it to the url attached to
I<myparam__>.  So if our exported handler referred to a URI
called I<script/scr.pl>, and the element on our HTML page called
I<div_id> contained the number '42', then the URL would look
like this C<script/scr.pl?myparam=42>.  The result from this
outside URL would get placed back into our HTML page in the
element I<resultdiv>.  See the example script that comes with
the distribution called I<pjx_url.pl> and its associated outside
script I<convert_degrees.pl> for a working example.

B<N.B.> These examples show the use of outside scripts which
are other perl scripts - I<but you are not limited to Perl>!
The outside script could just as easily have been PHP or any other
CGI script, as long as the return from the other script is just
the result, and not addition HTML code (like FORM elements, etc).

=back

=head2 GET versus POST

Note that all the examples so far have used the following syntax:

  onClick="exported_func(['input1'],['result1']);"

There is an optional third argument to a L<CGI::Ajax> exported
function that allows change the submit method.  The above event could
also have been coded like this...

  onClick="exported_func(['input1'],['result1'], 'GET');"

By default, L<CGI::Ajax> sends a I<'GET'> request.  If you need it,
for example your URL is getting way too long, you can easily switch
to a I<'POST'> request with this syntax...

  onClick="exported_func(['input1'],['result1'], 'POST');"

I<('POST' and 'post' are supported)>

=head2 Page Caching

We have implemented a method to prevent page cacheing from undermining
the AJAX methods in a page.  If you send in an input argument to a
L<CGI::Ajax>-exported function called 'NO_CACHE', the a special
parameter will get attached to the end or your url with a random
number in it.  This will prevent a browser from caching your request.

  onClick="exported_func(['input1','NO_CACHE'],['result1']);"

The extra param is called pjxrand, and won't interfere with the order
of processing for the rest of your parameters.

=head1 METHODS

=cut

################################### main pod documentation end ##

######################################################
## METHODS - public                                 ##
######################################################

=over 4

=item build_html()

    Purpose: Associates a cgi obj ($cgi) with pjx object, inserts
             javascript into <HEAD></HEAD> element and constructs
             the page, or part of the page.  AJAX applications
             are designed to update only the section of the
             page that needs it - the whole page doesn't have
             to be redrawn.  L<CGI::Ajax> applications use the
             build_html() method to take care of this: if the CGI
             parameter C<fname> exists, then the return from the
             L<CGI::Ajax>-exported function is sent to the page.
             Otherwise, the entire page is sent, since without
             an C<fname> param, this has to be the first time
             the page is being built.

  Arguments: The CGI object, and either a coderef, or a string
             containing html.  Optionally, you can send in a third
             parameter containing information that will get passed
             directly to the CGI object header() call.
    Returns: html or updated html (including the header)
  Called By: originating cgi script

=cut

sub build_html {
  my ( $self, $cgi, $html_source, $cgi_header_extra ) = @_;

  if ( ref( $cgi ) =~ /CGI*/ ) {
    if ( $self->DEBUG() ) {
      print STDERR "CGI::Ajax->build_html: CGI* object was received\n";
    }
    $self->cgi( $cgi ); # associate the cgi obj with the CGI::Ajax object
  }

  if ( defined $cgi_header_extra ) {
    if ( $self->DEBUG() ) {
      print STDERR "CGI::Ajax->build_html: got extra cgi header info\n";
      if ( ref($cgi_header_extra) eq "HASH" ) {
        foreach my $k ( keys %$cgi_header_extra ) {
          print STDERR "\t$k => ", $cgi_header_extra->{$k}, "\n";
        }
      } else {
        print STDERR "\t$cgi_header_extra\n";
      }
    }
    $self->cgi_header_extra( $cgi_header_extra ); 
  }

  #check if "fname" was defined in the CGI object
  if ( defined $self->cgi()->param("fname") ) {
    # it was, so just return the html from the handled request
    return ( $self->handle_request() );
  } else {
    
    # start with the minimum, a http header line and any extra cgi
    # header params sent in
    my $html = "";
    if ( $self->cgi()->can('header') ) {
      $html .= $self->cgi()->header( $self->cgi_header_extra() );
    } else {
      # don't have an object with a "header()" method, so just create
      # a mimimal one
      $html .= "Content-Type: text/html;";
      $html .= $self->cgi_header_extra();
      $html .= "\n\n";
    }

    # check if the user sent in a coderef for generating the html,
    # or the actual html
    if ( ref($html_source) eq "CODE" ) {
      if ( $self->DEBUG() ) {
        print STDERR "CGI::Ajax->build_html: html_source is a CODEREF\n";
      }
      eval { $html .= &$html_source };
      if ($@) {
        # there was a problem evaluating the html-generating function
        # that was sent in, so generate an error page
        if ( $self->cgi()->can('header') ) {
          $html = $self->cgi()->header( $self->cgi_header_extra() );
        } else {
          # don't have an object with a "header()" method, so just create
          # a mimimal one
          $html = "Content-Type: text/html;";
          $html .= $self->cgi_header_extra();
          $html .= "\n\n";
        }
        $html .= qq!<html><body><h2>Problems</h2> with
          the html-generating function sent to CGI::Ajax
          object</body></html>!;
        return $html;
      }
      $self->html($html);    # no problems, so set html
    } else {
      # user must have sent in raw html, so add it
      if ( $self->DEBUG() ) {
        print STDERR "CGI::Ajax->build_html: html_source is HTML\n";
      }
      $self->html( $html . $html_source );
    }

    # now modify the html to insert the javascript
    $self->insert_js_in_head();
  }
  return $self->html();
}

=item show_javascript()

    Purpose: builds the text of all the javascript that needs to be
             inserted into the calling scripts html <head> section
  Arguments:
    Returns: javascript text
  Called By: originating web script
       Note: This method is also overridden so when you just print
             a CGI::Ajax object it will output all the javascript needed
             for the web page.

=cut

sub show_javascript {
  my ($self) = @_;
  my $rv = $self->show_common_js();    # show the common js

  # build the js for each perl function you want exported to js
  foreach my $func ( keys %{ $self->coderef_list() }, keys %{ $self->url_list() } ) {
    $rv .= $self->make_function($func);
  }
  # wrap up the return in a CDATA structure for XML compatibility
  # (thanks Thos Davis)
  $rv = "\n" . '//<![CDATA[' . "\n" . $rv . "\n" . '//]]>' . "\n";
  $rv = '<script type="text/javascript">' . $rv . '</script>';
  return $rv;
}

## new
sub new {
  my ($class) = shift;
  my $self = bless ({}, ref ($class) || $class);
  $self->mk_accessors( qw(url_list coderef_list DEBUG JSDEBUG html ) );
  $self->JSDEBUG(0); # turn javascript debugging off (if on,
                     # extra info will be added to the web page output
                     # if set to 1, then the core js will get
                     # compressed, but the user-defined functions will
                     # not be compressed.  If set to 2 (or anything
                     # greater than 1 or 0), then none of the
                     # javascript will get compressed.
                     #
  $self->DEBUG(0);   # turn debugging off (if on, check web logs)

  #accessorized attributes
  $self->{coderef_list} = {};
  $self->{url_list} = {};
  $self->{html} = undef;
  $self->{cgi} = undef;
  $self->{cgi_header_extra} = {};

  if ( @_ < 2 ) {
    die "incorrect usage: must have fn=>code pairs in new\n";
  }

  while ( @_ ) {
    my($function_name,$code) = splice( @_, 0, 2 );
    if ( ref( $code ) eq "CODE" ) {
      if ( $self->DEBUG() ) {
        print STDERR "name = $function_name, code = $code\n";
      }
      # add the name/code to hash
      $self->coderef_list()->{ $function_name } = $code;
    } elsif ( ref($code) ) {
      die "Unsuported code block/url\n";
    } else {
      if ( $self->DEBUG() ) {
        print STDERR "Setting function $function_name to url $code\n";
      }
      # if it's a url, it is added here
      $self->url_list()->{ $function_name } = $code;
    }
  }
  return ($self);
}

######################################################
## METHODS - private                                ##
######################################################

# sub cgiobj(), cgi()
#
#    Purpose: accessor method to associate a CGI object with our
#             CGI::Ajax object
#  Arguments: a CGI object
#    Returns: CGI::Ajax objects cgi object
#  Called By: originating cgi script, or build_html()
#
sub cgiobj {
  my $self = shift;
  # see if any values were sent in...
  if ( @_ ) {
    my $cgi = shift;
    # add support for other CGI::* modules This requires that your web server
    # be configured properly.  I can't test anything but a mod_perl2
    # setup, so this prevents me from testing CGI::Lite,CGI::Simple, etc.
    if ( ref($cgi) =~ /CGI*/ ) {
      $self->{'cgi'} = $cgi;
    } else {
      die "CGI::Ajax -- Can't set internal CGI object to a non-CGI object\n";
    }
  }
  # return the object
  return( $self->{'cgi'} );
}

sub cgi {
  my $self = shift;
  if ( @_ ) {
    return( $self->cgiobj( @_ ) );
  } else {
    return( $self->cgiobj() );
  }
}

# sub cgi_header_extra
#
#    Purpose: accessor method to associate CGI header information
#             with the CGI::Ajax object
#  Arguments: a hashref with key=>value pairs that get handed off to
#             the CGI object's header() method
#    Returns: hashref of extra cgi header params
#  Called By: originating cgi script, or build_html()

sub cgi_header_extra {
  my $self = shift;
  if ( @_ ) {
    $self->{'cgi_header_extra'} = shift;
  }
  return( $self->{'cgi_header_extra'} );
}

# sub show_common_js()
#
#    Purpose: create text of the javascript needed to interface with
#             the perl functions
#  Arguments: none
#    Returns: text of common javascript subroutine, 'do_http_request'
#  Called By: originating cgi script, or build_html()
#

sub show_common_js {
  my $self = shift;
  my $rv = <<EOT;
var ajax = [];
function pjx(args,fname,method) {
  this.dt=args[1];
  this.args=args[0];
  method=(method)?method:'GET';
  if(method=='post'){method='POST';}
  this.method = method;
  this.r=ghr();
  this.url = this.getURL(fname);
}

function getVal(id) {
  if (id.constructor == Function ) { return id; }
  if (typeof(id)!= 'string') { return id; }
  var element = document.getElementById(id);
  if (element.type == 'select-multiple') {
  var ans = new Array();
    for (var i=0;i<element.length;i++) {
      if (element[i].selected) {
        ans.push(element[i].value);
      }
    }
    return ans;
  }
  if(element.type == 'radio'){
    var ans =[];
    var elms = document.getElementsByTagName('input');
    var endk = elms.length;
    for(var k=0;k<endk;k++){
      if(elms[k].type=='radio' && elms[k].checked && elms[k].id==id){
        ans.push(elms[k].value);
      }
    }
    return ans;
  }
  try {
    return element.value.toString();
  } catch(e) {
    try {
      return element.innerHTML.toString();
    } catch(e) {
      var errstr = 'ERROR: cant get html element with id:' +
      id + '.  Check that an element with id=' + id + ' exists';
      alert(errstr);
      return false;
    }
  }
}

function fnsplit(arg) {
  var arg2="";
  if (arg == 'NO_CACHE') { return '&_pjxrand_='  + Math.random() }
  if (arg.indexOf('__') != -1) {
    arga = arg.split(/__/);
    arg2 += '&' + arga[0] +'='+ encodeURIComponent(arga[1]);
  } else {
    var ans = getVal(arg);
    if ( typeof ans != 'string' ) {
      if ( ans.length == 0 ) { arg2 += '&args=&' + arg + '='; }
      for (var i=0;i < ans.length;i++) {
        arg2 += '&args=' + encodeURIComponent(ans[i]) + '&' + arg + '=' + encodeURIComponent(ans[i]);
      }
    } else {
      arg2 += '&args=' + encodeURIComponent(ans) + '&' + arg + '=' + encodeURIComponent(ans);;
    }
  }
  return arg2;
}

pjx.prototype.send2perl=function() {
  var r = this.r;
	var dt = this.dt;
  var url=this.url;
  var postdata;
  if(this.method=="POST"){
    var idx=url.indexOf('?');
    postdata = url.substr(idx+1);
    url = url.substr(0,idx);
  }
  r.open(this.method,url,true);
  if(this.method=="POST"){
    r.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    r.send(postdata);
  }
  if(this.method=="GET"){
    r.send(null);
  }
  r.onreadystatechange=handleReturn;
};

handleReturn = function() {
  for( var k=0; k<ajax.length; k++ ) {
    if (ajax[k].r==null) { ajax.splice(k--,1); continue; }
    if ( ajax[k].r.readyState== 4) { 
      var rsp = ajax[k].r.responseText;  /* the response from perl */
      var splitval = '__pjx__';  /* to split text */
      /* fix IE problems with undef values in an Array getting squashed*/
      rsp = rsp.replace(splitval+splitval+'g',splitval+" "+splitval);
      var data = rsp.split(splitval);  
      dt = ajax[k].dt;
      if (dt.constructor != Array) { dt=[dt]; }
      if (data.constructor != Array) { data=[data]; }
      if (typeof(dt[0])!='function') {
        for ( var i=0; i<dt.length; i++ ) {
          var div = document.getElementById(dt[i]);
          if (div.type =='text' || div.type=='textarea' || div.type=='hidden' ) {
            div.value=data[i];
          } else{
            div.innerHTML = data[i];
          }
        }
      } else if (typeof(dt[0])=='function') {
         var d=data;
         var str = "dt[0](";
         for(m=0;m<d.length-1;m++){
           str+= "d[" + m + "],";
         }
         str+="d[" + m +"])";
         eval(str);
      }
      ajax.splice(k--,1);
    }
  }
};

pjx.prototype.getURL=function(fname) {
  var args = this.args;
  var url= 'fname=' + fname;
  for (var i=0;i<args.length;i++) {
    url=url + args[i];
  }
  return url;
};
var ghr=getghr();
function getghr(){
    if(typeof XMLHttpRequest != "undefined")
    {
        return function(){return new XMLHttpRequest();}
    }
    var msv= ["Msxml2.XMLHTTP.7.0", "Msxml2.XMLHTTP.6.0",
    "Msxml2.XMLHTTP.5.0", "Msxml2.XMLHTTP.4.0", "MSXML2.XMLHTTP.3.0",
    "MSXML2.XMLHTTP", "Microsoft.XMLHTTP"];
    for(var j=0;j<=msv.length;j++){
        try
        {
            A = new ActiveXObject(msv[j]);
            if(A){ 
              return function(){return new ActiveXObject(msv[j]);}
            }
        }
        catch(e) { }
     }
     return false;
}


function jsdebug(){
    var tmp = document.getElementById('pjxdebugrequest').innerHTML = "<br><pre>";
    for( var i=0; i < ajax.length; i++ ) {
      tmp += '<a href= '+ ajax[i].url +' target=_blank>' +
      decodeURIComponent(ajax[i].url) + ' </a><br>';
    }
    document.getElementById('pjxdebugrequest').innerHTML = tmp + "</pre>";
}

EOT

  my $sig = <<EOS;
//
// created by:
// Brian C. Thomas bct.x42\@gmail.com
// Brent Pedersen bpederse\@gmail.com
// distributed under the Perl Artistic license
// See LICENSE file included
//
EOS

  if ( $self->JSDEBUG() <= 1 ) {
    $rv = $self->compress_js($rv);
  }

  return($sig . $rv);
}

# sub compress_js()
#
#    Purpose: searches the javascript for newlines and spaces and
#             removes them (if a newline) or shrinks them to a single (if
#             space).
#  Arguments: javascript to compress
#    Returns: compressed js string
#  Called By: show_common_js(),
#

sub compress_js {
  my($self,$js) = @_;
  return if not defined $js;
  return if $js eq "";
  $js =~ s/\n//g;   # drop newlines
  $js =~ s/\s+/ /g; # replace 1+ spaces with just one space
  return $js;
}


# sub insert_js_in_head()
#
#    Purpose: searches the html value in the CGI::Ajax object and inserts
#             the ajax javascript code in the <script></script> section,
#             or if no such section exists, then it creates it.  If
#             JSDEBUG is set, then an extra div will be added and the
#             url wil be desplayed as a link
#  Arguments: none
#    Returns: none
#  Called By: build_html()
#

sub insert_js_in_head{
  my $self = shift;
  my $mhtml = $self->html();
  my $newhtml;
  my @shtml;
  my $js = $self->show_javascript();

  if ( $self->JSDEBUG() ) {
    my $showurl=qq!<br/><div id='pjxdebugrequest'></div><br/>!;
    # find the terminal </body> so we can insert just before it
    my @splith = $mhtml =~ /(.*)(<\s*\/\s*body\s*>)(.*)/is;
    $mhtml = $splith[0].$showurl.$splith[1].$splith[2];
  }

  # see if we can match on </head>
  @shtml= $mhtml =~ /(.*)(<\s*\/\s*head\s*>)(.*)/is;
  if ( @shtml ) {
    # yes, there's already a <head></head>, so let's insert inside it,
    # at the end
    $newhtml = $shtml[0].$js.$shtml[1].$shtml[2];
  } elsif( @shtml= $mhtml =~ /(.*)(<\s*html.*?>)(.*)/is){
    # there's no <head>, so look for the <html> tag, and insert out
    # javascript inside that tag
    $newhtml = $shtml[0].$shtml[1].$js.$shtml[2];
  } else {
    $newhtml .= "<html><head>";
    $newhtml .= $js;
    $newhtml .= "</head><body>";
    $newhtml .= "No head/html tags, nowhere to insert.  Returning javascript anyway<br>";
    $newhtml .= "</body></html>";
  }
  $self->html($newhtml);
  return;
}

# sub handle_request()
#
#    Purpose: makes sure a fname function name was set in the CGI
#             object, and then tries to eval the function with
#             parameters sent in on args
#  Arguments: none
#    Returns: the result of the perl subroutine, as text; if multiple
#             arguments are sent back from the defined, exported perl
#             method, then join then with a connector (__pjx__).
#  Called By: build_html()
#

sub handle_request {
  my ($self) = shift;

  my $result; # $result takes the output of the function, if it's an
              # array split on __pjx__
  my @other = (); # array for catching extra parameters

  # we need to access "fname" in the form from the web page, so make
  # sure there is a CGI object defined
  return undef unless defined $self->cgi();

  my $rv = "";
  if ( $self->cgi()->can('header') ) {
    $rv = $self->cgi()->header( $self->cgi_header_extra() );
  } else {
    # don't have an object with a "header()" method, so just create
    # a mimimal one
    $rv = "Content-Type: text/html;";
    $rv .= $self->cgi_header_extra();
    $rv .= "\n\n";
  }

  # get the name of the function
  my $func_name = $self->cgi()->param("fname");

  # check if the function name was created
  if ( defined $self->coderef_list()->{$func_name} ) {
    my $code = $self->coderef_list()->{$func_name};

    # eval the code from the coderef, and append the output to $rv
    if ( ref($code) eq "CODE" ) {
      eval { ($result, @other) = $code->( $self->cgi()->param("args") ) };

      if ($@) {
        # see if the eval caused and error and report it
        # Should we be more severe and die?
        if ( $self->DEBUG() ) {
          print STDERR "Problem with code: $@\n";
        }
      }

      if( @other ) {
          $rv .= join( "__pjx__", ($result, @other) );
          if ( $self->DEBUG() ) {
            print STDERR "rv = $rv\n";
          }
      } else {
        if ( defined $result ) {
          $rv .= $result;
        }
      }

    } # end if ref = CODE
  } else {
    # # problems with the URL, return a CGI rrror
    print STDERR "POSSIBLE SECURITY INCIDENT! Browser from ", $self->cgi()->remote_addr();
    print STDERR "\trequested URL: ", $self->cgi()->url();
    print STDERR "\tfname request: ", $self->cgi()->param('fname');
    print STDERR " -- returning Bad Request status 400\n";
    if ( $self->cgi()->can('header') ) {
      return($self->cgi()->header( -status=>'400' ));
    } else {
      # don't have an object with a "header()" method, so just create
      # a mimimal one with 400 error
      $rv = "Status: 400\nContent-Type: text/html;\n\n";
    }
  }
  return $rv;
}


# sub make_function()
#
#    Purpose: creates the javascript wrapper for the underlying perl
#             subroutine
#  Arguments: CGI object from web form, and the name of the perl
#             function to export to javascript, or a url if the
#             function name refers to another cgi script
#    Returns: text of the javascript-wrapped perl subroutine
#  Called By: show_javascript; called once for each registered perl
#             subroutine
#

sub make_function {
  my ($self, $func_name ) = @_;
  return("") if not defined $func_name;
  return("") if $func_name eq "";
  my $rv = "";
  my $script = $0;
  $script =~ s/.*\/(.+)$/$1/;
  my $outside_url = $self->url_list()->{ $func_name };
  my $url = defined $outside_url ? $outside_url : $script;
  if ($url =~ /\?/) { $url.='&'; } else {$url.='?'}
  $url = "'$url'";
  my $jsdebug = "";
  if ( $self->JSDEBUG()) {
    $jsdebug = "jsdebug()";
  }

  #create the javascript text
  $rv .= <<EOT;
function $func_name() {
  var args = $func_name.arguments;
  for( var i=0; i<args[0].length;i++ ) {
    args[0][i] = fnsplit(args[0][i]);
  }
  var l = ajax.length;
  ajax[l]= new pjx(args,"$func_name",args[2]);
  ajax[l].url = $url + ajax[l].url;
  ajax[l].send2perl();
  $jsdebug;
}
EOT

  if ( not $self->JSDEBUG() ) {
    $rv = $self->compress_js($rv);
  }
  return $rv;
}

=item register()

    Purpose: adds a function name and a code ref to the global coderef
             hash, after the original object was created
  Arguments: function name, code reference
    Returns: none
  Called By: originating web script

=cut

sub register {
  my ( $self, $fn, $coderef ) = @_;
  # coderef_list() is a Class::Accessor function
  # url_list() is a Class::Accessor function
  if ( ref( $coderef ) eq "CODE" ) {
    $self->coderef_list()->{$fn} = $coderef;
  } elsif ( ref($coderef) ) {
    die "Unsupported code/url type - error\n";
  } else {
    $self->url_list()->{$fn} = $coderef;
  }
}

=item JSDEBUG()

    Purpose: Show the AJAX URL that is being generated, and stop
             compression of the generated javascript, both of which can aid
             during debugging.  If set to 1, then the core js will get
             compressed, but the user-defined functions will not be
             compressed.  If set to 2 (or anything greater than 1 or 0), 
             then none of the javascript will get compressed.

  Arguments: JSDEBUG(0); # turn javascript debugging off
             JSDEBUG(1); # turn javascript debugging on, some javascript compression
             JSDEBUG(2); # turn javascript debugging on, no javascript compresstion
    Returns: prints a link to the url that is being generated automatically by
             the Ajax object. this is VERY useful for seeing what
             CGI::Ajax is doing. Following the link, will show a page
             with the output that the page is generating.
             
  Called By: $pjx->JSDEBUG(1) # where $pjx is a CGI::Ajax object;

=item DEBUG()

    Purpose: Show debugging information in web server logs
  Arguments: DEBUG(0); # turn debugging off (default)
             DEBUG(1); # turn debugging on
    Returns: prints debugging information to the web server logs using
             STDERR
  Called By: $pjx->DEBUG(1) # where $pjx is a CGI::Ajax object;

=back

=head1 BUGS

Follow any bugs at our homepage....

  http://www.perljax.us

=head1 SUPPORT

Check out the news/discussion/bugs lists at our homepage:

  http://www.perljax.us

=head1 AUTHORS

  Brian C. Thomas     Brent Pedersen
  CPAN ID: BCT
  bct.x42@gmail.com   bpederse@gmail.com

=head1 A NOTE ABOUT THE MODULE NAME

This module was initiated using the name "Perljax", but then
registered with CPAN under the WWW group "CGI::", and so became
"CGI::Perljax".  Upon further deliberation, we decided to change it's
name to L<CGI::Ajax>.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Data::Javascript>
L<CGI>
L<Class::Accessor>

=cut

1;
__END__
