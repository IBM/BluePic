#!/usr/bin/perl
# Author: Kyle Craig
use strict;
use warnings;

use Path::Class;
use Cwd;
use autodie;
use Getopt::Long;

my $cloudant_db = "";
my $password 	= "";
my $output		= "";
my $update		= "";
GetOptions( "db=s" 			=> \$cloudant_db,
			"password=s" 	=> \$password,
			"output=s" 		=> \$output,
			"update=s"		=> \$update)
or die(usage());

sub usage
{
	print ("USAGE: \n");
	print ("cloudant_update.pl -d CLOUDANT_DB -p PASSWORD [-o FILENAME] [-u FILENAME]\n");
	print ("\t-d CLOUDANT_DB is the URL of the cloudant database you want to access.\n");
	print ("\t-p PASSWORD is the password for the cloudant database.\n");
	print ("\t-o FILENAME is used when you want to download your database to an uploadable local json file.\n");
	print ("\t-u FILENAME is used when you want to update the cloudant database with a local json file.\n");
	print ("\tIf both -o and -u are used, the -u will be ignored.\n");
	exit();
}

if ($cloudant_db eq "") {
	print ("No Cloudant database given. \n\n");
	usage();
} 

my $username = "";
if ($cloudant_db =~ /https:\/\/(.+)\.cloudant.com/) {
	$username = $1;
} else {
	print "Invalid URL.\n";
	exit();
}

if ($output ne "") {
	downloadDB();
}

if ($update ne "") {
	uploadDB();
}

print ("Need to select either -o or -u. \n\n");
usage();

sub downloadDB
{
	print "Download from $cloudant_db\n";
	my $all_docs = "$cloudant_db/_all_docs?include_docs=true";

	my $json = `curl -X GET $all_docs -u $username:$password`;

	if ($json =~ /error/) {
		print $json;
		exit();
	} 

	chomp $json;
    my $tempfile = 'db_raw.json';
    my $fh;
    open($fh, '>', 'db_raw.json') or die "Could not open file db_raw.json $!";
    print $fh $json;
    system "doc_convert.sh $tempfile $output";
    close($fh);
    `rm db_raw.json`;

	exit();
}

sub uploadDB 
{	
	print "Upload to $cloudant_db\n";

	# Delete all docs from cloudant before upload
	my $cwd = getcwd(); # current working directory
	my $dir = dir($cwd); # convert directory to dir object
	my $file = $dir->file($update); # get file out of directory
	my $content = $file->slurp(); # read in the entire contents of a file
	my $read_handle = $file->openr(); # open a file handle to read from
	my $fh; # output file handler to write to

	# Read in line at a time
	while( my $line = $read_handle->getline() ) {

		if ($line =~ /"_id":"(.+?)"/) {
			my $id = $1;
			my $response = `curl -i -X GET $cloudant_db/$id -u $username:$password`;
			if ($response =~ /Etag: "(.+?)"/) {
				my $rev = $1;
				print "DELETING $id - $rev\n";
				print `curl -X DELETE $cloudant_db/$id\?rev\=$rev -u $username:$password`;
			}
		}
	}

	print `curl -X POST $cloudant_db/_bulk_docs  -H "Content-Type:application/json" -d \@$update -u $username:$password`;

	exit();
}