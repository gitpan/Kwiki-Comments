package Kwiki::Comments;
use strict;
use warnings;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';
use YAML;
use DBI;

our $VERSION = '0.01';

const class_id => 'comments';
const class_title => 'Kwiki Comments';
const cgi_class => 'Kwiki::Comments::CGI';
const screen_template => 'comments_form.html';
const css_file => 'comments.css';

sub register {
    my $registry = shift;
    $registry->add( action => 'comments' );
    $registry->add( action => 'comments_post' );
    $registry->add( wafl => comments => 'Kwiki::Comments::Wafl' );
}

sub dbinit {
    my $db = shift;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","",
			   { RaiseError => 1, AutoCommit => 1 });
    $dbh->do('CREATE TABLE comments (author,url,email,text)');
    $dbh->disconnect;
}

sub dbpath {
    my $page_id =$self->hub->pages->current->id;
    my $path = $self->plugin_directory;
    my $filename =  io->catfile($path,"$page_id.sqlt")->name;
    $self->dbinit($filename) unless -f $filename;
    return $filename;
}

sub db_connect {
    my $db  = $self->dbpath;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","",
			   { RaiseError => 1, AutoCommit => 1 });
    return $dbh;
}

sub load_comments {
    my @comments;
    my $dbh = $self->db_connect;
    my $sth = $dbh->prepare("SELECT * FROM comments");
    $sth->execute;
    while(my $data = $sth->fetchrow_hashref) {
	push @comments, $data;
    }
    $sth->finish;
    $dbh->disconnect;
    return \@comments;
}

sub add_comment {
    my $dbh = $self->db_connect;
    my $sth = $dbh->prepare("INSERT INTO comments values(?,?,?,?)");
    $sth->execute(@_);
    $sth->finish;
    $dbh->disconnect;
}

sub comments_post {
    my $cgi = $self->cgi;
    my $page_id = $self->hub->pages->current->id;
    $self->add_comment($cgi->author, $cgi->email, $cgi->url, $cgi->text);
    $self->redirect("$page_id");
}

sub comments {
    $self->render_screen;
}

package Kwiki::Comments::Wafl;
use base 'Spoon::Formatter::WaflPhrase';
use YAML;

sub to_html {
    my $friend = $self->hub->comments;

    my $content =
	$friend->template_process('comments_display.html',
				  comments => $friend->load_comments )
	    . $friend->template_process('comments_form.html');
}

package Kwiki::Comments::CGI;
use Kwiki::CGI '-base';

cgi 'author';
cgi 'email';
cgi 'url';
cgi 'text';

package Kwiki::Comments;
__DATA__
=head1 NAME

Kwiki::Comments - Post comments to a page

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
__template/tt2/comments_display.html__
<!-- BEGIN comments_display.html -->
<hr />
<div class="comments-display">
[% FOR post = comments %]
[% IF post.url %]
[% link = post.url %]
[% ELSIF post.email %]
[% link = "mailto:" + post.email %]
[% ELSE %]
[% link = '' %]
[% END %]
<div class="comments-body">
<span class="comments-post">Posted by
[% IF link %]
    <a href="[% link %]">[% post.author%]</a>
[% ELSE %]
    [% post.author %]
[% END %]
</span>
<p>[% post.text %]</p>
</div>
[% END %]
</div>
<!-- END comments_display.html -->
__template/tt2/comments_form.html__
<!-- BEGIN comments_form.html -->
<hr />
<div class="comments-form">
<div class="comments-head">Post a comment</div>
<div class="comments-body">
<form method="post" action="[% script_name %]" name="comments_form">

<input type="hidden" name="action" value="comments_post" />
<input type="hidden" name="page_id" value="[% page_id %]" />

<label for="author">Name:</label><br />
<input id="author" name="author" /><br /><br />
<label for="email">Email Address:</label><br />
<input id="email" name="email" /><br /><br />
<label for="url">URL:</label><br />
<input id="url" name="url" /><br /><br />
<label for="text">Comments:</label><br />
<textarea id="text" name="text" rows="10" cols="50"></textarea><br /><br />
<input type="submit" id="submit" name="submit" />
</div>
</div>
<!-- END comments_form.html -->
