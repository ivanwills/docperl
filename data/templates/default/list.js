[% UNLESS history_size %][% history_size = 10 %][% END -%]
/**	
 *	@file:	list.js
 *	@author:	Ivan Wills
 *	
 *	
 *	This file contains the javascript for controlling the module list of DocPerl
 *	
 */

/**	
 *	@param	counter:	
 *	@param	amount:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function add_count( counter, amount ) {
	var counter_span = document.getElementById( counter + '_count' );
	var counter_value = counter_span.firstChild.nodeValue;
	counter_value -= -amount;
	counter_span.removeChild( counter_span.firstChild );
	counter_span.appendChild( document.createTextNode( counter_value ) );

/**	
 *	@param	counter:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */

function reset_count( counter ) {
	var counter_span = document.getElementById( counter + '_count' );
	
	counter_span.removeChild( counter_span.firstChild );
	counter_span.appendChild( document.createTextNode( '0' ) );
}

/**	
 *	@param	tree:	
 *	@param	counter:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function count_tree( tree, counter ) {
	var count = 0;
	for ( var module in tree ) {
		if ( module != '*' ) {
			data = tree[module];
			var tt = new Array();
			for ( var t in data )
				tt.push(t);
			if ( data && tt.length ) {
				count_tree( data, counter );
				count++;
			}
		}
	}
	add_count( counter, count );
}

/**	
 *	@param	files:	
 *	@param	container_id:	
 *	@param	path:	
 *	@param	counter:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
var tree_holder = new Array();
function create_tree ( files, container_id, path, counter ) {
	// need to stick each module into a container
	var container= document.getElementById(container_id);
	var ul		 = document.createElement('ul');
	var count	 = 0;
	ul.className = 'mod_list';
	ul.id		 = 'ul__'+path;
	level++;
	if ( !counter )
		counter = path;
	else
		ul.style.display = 'none';
	if (!files)
		files = tree_holder[path];
	
	var files_sort = new Array();
	for ( var module in files ) {
		files_sort.push(module);
	}
	files_sort.sort();
	
	for ( var module in files_sort ) {
		module = files_sort[module];
		if ( module != '*' ) {
			var li	= document.createElement('li');
			li.id	= 'li__' + path + '__' + module;
			var label;
			var data	= files[module];
			var num		= 0;
			for ( var sub in data ) {
				num++;
			}
			
			// the javascript contains only one element if there are no sub directories
			li.appendChild( create_plus( num >= 2 ? path + '__' + module : null ) );
			
			data = files[module]['*'];
			if ( data && data.length ) {
				label = create_module( path + '__' + module, module );
				count++;
			}
			else {
				label = document.createTextNode( module );
			}
			li.appendChild( label );
			
			var time = 50 + Math.floor( Math.random() * 50 );
			// recurse to get sub elements here
			tree_holder[path + '__' + module] = files[module];
			var func = 'create_tree(null, "'+li.id+'", "'+path + '__' + module+'", "'+counter+'")';
			//setTimeout( func, time );
			//setTimeout( create_tree, time, files[module], li.id, path + '__' + module, counter );
			ul.appendChild( li );
		}
	}
	
	container.appendChild( ul );
	//add_count( counter, count );
	return count;
}

/**	
 *	@param	path:	
 *	@param	module:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function create_module(path, module) {
	var display = path;
	display.replace(/__/g, '::');
	var label	= document.createElement('a');
	label.href	= '?page=module&module=' + path;
	label.title = display;
	label.setAttribute( 'onclick', 'javascript: click_module("' + path + '");' );
	label.setAttribute( 'target', '[% IF !sidebar %]main[% ELSE %]_content[% END %]' );
	label.appendChild( document.createTextNode( module ) );
	
	return label;
}

/**	
 *	@param	path:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function create_plus(path) {
	var plus;
	// the javascript contains only one element if there are no sub directories
	if ( path ) {
		plus				= document.createElement('a');
		plus.id				= 'plus__' + path;
		plus.href			= 'javascript: list_toggle("' + path + '")';
		plus.title			= 'Show';
		plus.className		= 'mod_expand';
		plus.style.cssText	= 'text-decoration: none';
		plus.appendChild( document.createTextNode( '+' ) );
	}
	else {
		plus				= document.createElement('div');
		plus.className		= 'mod_expand';
		plus.style.cssText	= 'border-width: 0px;';
		plus.appendChild( document.createTextNode( '.' ) );
	}
	
	return plus;
}

/**	
 *	@param	path:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function click_module( path ) {
	var name = 'DocPerl_recent';
	if ( exists_cookie( name ) ) {
		var list	= get_cookie( name );
		var modules	= list.split(':');
		for ( var module in modules ) {
			if ( modules[module] == path )
				return;
		}
		list += ':' + path;
		modules.push(path);
		if ( modules.length >= [% history_size %] ) {
			var recent = document.getElementById('ul_recent');
			recent.removeChild( recent.firstChild );
			add_count( 'recent', -1 );
			modules.splice( 0,  modules.length - [% history_size %] );
		}
		set_cookie( name, modules.join(':') );
	}
	else {
		set_cookie( name, path );
	}
	display_recent(path);
}

/**	
 *	@param	path:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function display_recent(path) {
	var path_parts	= path.split('__');
	var recent_doc	= document.getElementById('recent_doc');
	var recent_ul	= document.getElementById('ul_recent');
	var name		= '';
	recent_doc.style.cssText = '';
	recent_doc.style.display = 'block';
	
	for ( var i = 2; i < path_parts.length; i++ ) {
		if ( i != 2 )
			name += '::';
		name += path_parts[i];
	}
	
	var li	= document.createElement('li');
	li.appendChild( create_plus() );
	li.appendChild( create_module( path, name ) );
	
	recent_ul.appendChild( li );
	add_count( 'recent', 1 );
}

/**	
 *	@param	force:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function search(force) {
	var string		= document.getElementById('search').value;
	var results_doc	= document.getElementById('results_doc');
	
	if ( !force && string.length < 4 )
		return;
	if ( !string ) {
		results_doc.style.cssText = 'display:none';
		return;
	}
	
	var terms		= string.split(/\s+/);
	var results		= document.getElementById('results');
	var ul			= document.createElement('ul');
	results_doc.style.cssText = '';
	
	while (results.firstChild)
		results.removeChild(results.firstChild);
	
	ul.id = 'ul__results';
	results.appendChild(ul);
	reset_count('results');
	
	for ( var i in terms ) {
		var term = terms[i];
		
		var list = show_found( new Array(perl.POD), term, 'perl__', 'POD' );
		if ( list )
			ul.appendChild( list );
		list = show_found( local, term, 'local__', 'Local' );
		if ( list )
			ul.appendChild( list );
		list = show_found( inc, term, 'inc__', 'Installed' );
		if ( list )
			ul.appendChild( list );
	}
}

/**	
 *	@param	list:	
 *	@param	term:	
 *	@param	base:	
 *	@param	name:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function show_found( list, term, base, name ) {
	var count	= 0;
	var li		= document.createElement('li');
	var ul_sub	= document.createElement('ul');
	var path	= 'results__' + base;
	li.id		= 'li__' + path;
	ul_sub.id	= 'ul__' + path;
	li.appendChild( create_plus(path) );
	li.appendChild( document.createTextNode(name) );
	
	for ( var i in list ) {
		var item	= list[i];
		var found	= find_in( item, term );
		
		if ( found.length ) {
			count += found.length;
			
			for ( var item in found ) {
				var li_sub	= document.createElement('li');
				var name	= found[item];
				name = name.replace( /::/g, '__' );
				
				li_sub.appendChild( create_plus() );
				li_sub.appendChild( create_module( path + '__' + name, found[item] ) );
				ul_sub.appendChild(li_sub);
			}
		}
	}
	
	if ( !count )
		return null;
	
	add_count( 'results', count );
	li.appendChild(ul_sub);
	
	return li;
}

/**	
 *	@param	object:	
 *	@param	term:	
 *	@param	name:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function find_in( object, term, name ) {
	var next	= name ? name + '::' : '';
	var found	= new Array();
	var regex	= new RegExp( term, 'i' );
	
	for ( var item in object ) {
		var module = next + item;
		
		// Check if the node is actually a module and if it matches the re
		if ( object[item]['*'] && object[item]['*'].length && module.match( regex ) ) {
			found.push( module );
		}
		
		// itterate to sub modules
		if ( item != '*' ) {
			var matches = find_in( object[item], term, module );
			for ( var i in matches )
				found.push( matches[i] );
		}
	}
	return found;
}

/**	
 *	@param	id:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function list_toggle( id ) {
	var ul		= document.getElementById( 'ul__' + id );
	if (!ul) {
		create_tree( null, 'li__'+id, id, 'inc');
		ul		= document.getElementById( 'ul__' + id );
	}
	var link	= document.getElementById( 'plus__' + id );
	// check the status of the list
	if ( ul.style && ul.style.display == 'block' ) {
		// list is open so close
		ul.style.display = 'none';
		link.removeChild( link.firstChild );
		link.appendChild( document.createTextNode('+') );
		link.title = 'Show';
	}
	else {
		// list is closed so open
		ul.style.display = 'block';
		link.removeChild( link.firstChild );
		link.appendChild( document.createTextNode('-') );
		link.title = 'Hide';
	}
}

/**	
 *	@param	section:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function section_toggle( section ) {
	var div		= document.getElementById( section );
	var head	= document.getElementById( section + '_head' );
	var link	= document.getElementById( 'plus__' + section );
	// check the status of the list
	if ( div.style && div.style.display ) {
		// list is closed so open
		div.style.display = '';
		head.style.marginBottom = '';
		link.removeChild( link.firstChild );
		link.appendChild( document.createTextNode('-') );
		link.title = 'Show';
	}
	else {
		// list is open so close
		div.style.display = 'none';
		head.style.marginBottom = '1px';
		link.removeChild( link.firstChild );
		link.appendChild( document.createTextNode('+') );
		link.title = 'Hide';
	}
}

/**	
 *	@param	name:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function get_cookie(name) {
	var result			= null;
	var my_cookie		= " " + document.cookie + "; ";
	var search_name		= " " + name + "=";
	var start_of_cookie	= my_cookie.indexOf(search_name);
	var end_of_cookie;
	
	if (start_of_cookie != -1) {
		start_of_cookie += search_name.length;
		// skip past cookie name
		end_of_cookie = my_cookie.indexOf(";",start_of_cookie);
		result = unescape(my_cookie.substring(start_of_cookie, end_of_cookie));
	}
	
	return result
}

/**	
 *	@param	name:	
 *	@param	value:	
 *	@param	expires:	
 *	@param	path:	
 *	@param	domain:	
 *	@param	secure:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function set_cookie(name, value, expires, path, domain, secure) {
	var expString	 = expires	== null	? "" : ("; expires=" + expires.toGMTString());
	var pathString	 = path		== null	? "" : ("; path=" + path);
	var domainString = domain	== null	? "" : ("; domain=" + domain);
	var secureString = secure	== true	? "; secure" : "";
	var new_cookie	 = name + "=" + escape(value) + expString + pathString + domainString + secureString;
	document.cookie	 = new_cookie;
}

/**	
 *	@param	name:	
 *	@param	path:	
 *	@param	domain:	
 *	@param	secure:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function clear_cookie(name, path, domain, secure) {
	var ThreeDays	= 3 * 24 * 60 * 60 * 1000;
	var expDate		= new Date();
	expDate.setTime(expDate.getTime() - ThreeDays);
	set_cookie(name, "ImOutOfHere", expDate, path, domain, secure)
}

/**	
 *	@param	cookie:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function exists_cookie(cookie) {
	return (get_cookie(cookie) == null) ? false : true;
}

/**	
 *	@param	name:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function get_cookie_count(name) {
	var result			= 0;
	var my_cookie		= " " + document.cookie + ";";
	var search_name		= " " + name + "=";
	var name_length		= search_name.length;
	var start_of_cookie	= myCookie.indexOf(search_name);
	
	while (start_of_cookie != -1) {
		result += 1;
		start_of_cookie = my_cookie.indexOf(search_name, start_of_cookie + name_length);
	}
	return result;
}

/**	
 *	@param	name:	
 *	@param	cookie_num:	
 *	@return	:	
 *	@todo	implementation
 *	@bug	
 *	
 *	
 */
function get_cookie_number(name, cookie_num) {
	var result = null;
	if (cookie_num >= 1) {
		var cntr			= 0;
		var my_cookie		= " " + document.cookie + ";";
		var search_name		= " " + name + "=";
		var name_length		= search_name.length;
		var start_of_cookie	= my_cookie.indexOf(search_name);
		
		for (cntr = 1; cntr < cookie_number; cntr++) {
			start_of_cookie = my_cookie.indexOf(search_name, start_of_cookie + name_length);
		}
		
		if (start_of_cookie != 1) {
			start_of_cookie	 += name_length; // skip past cookie name
			var end_of_cookie = my_cookie.indexOf(";", start_of_cookie);
			result = unescape(my_cookie.substring(start_of_cookie, end_of_cookie));
		}
	}
	return result;
}
