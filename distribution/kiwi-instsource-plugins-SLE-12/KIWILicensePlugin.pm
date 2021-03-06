################################################################
# Copyright (c) 2014 SUSE
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file LICENSE); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
################################################################
package KIWILicensePlugin;

use strict;
use warnings;

use base "KIWIBasePlugin";

sub new {
	my $class   = shift;
	my $handler = shift;
	my $config  = shift;
	my $this = KIWIBasePlugin -> new ($handler);
	bless ($this, $class);
	my $ini = Config::IniFiles -> new (
		-file => "$config"
	);
	my $name = $ini->val('base', 'name');
	my $order = $ini->val('base', 'order');
	my $enable = $ini->val('base', 'defaultenable');
	if (not defined($name)
		or not defined($order)
		or not defined($enable)
	) {
		$this->logMsg(
			"E", "Plugin ini file <$config> seems broken!"
		);
		return;
	}
	$this->name($name);
	$this->order($order);
	if ($enable != 0) {
		$this->ready(1);
	}
	return $this;
}

sub execute {
	my $this = shift;
	my $result;
	for my $cd ($this->collect()->getMediaNumbers()) {
		next if $cd == 0;
		my $name = $this->collect()->{m_basesubdir}->{$cd};
		$name =~ s{.*/(.*)/*$}{$1}x;
		my $media_base = $this->collect()->{m_united}."/$name";
		my $media_license_dir = $this->collect()->{m_united}
			."/".$name.".license";
		$this->logMsg(
			"I", "Check for licenses on media $media_base"
		);
		my $licenseArchive = "$media_base/license.tar.gz";
		if ( -e $licenseArchive ) {
			$this->logMsg("I", "Extracting license.tar.gz");
			system("mkdir $media_license_dir");
			$result = $? >> 8;
			if ($result != 0) {
				return 1;
			}
			system("tar xf $licenseArchive -C $media_license_dir");
			$result = $? >> 8;
			if ($result != 0) {
				return 1;
			}
			# add license information to repomd metadata
			if ( -e "$media_base/repodata" ) {
				$this->logMsg("I", "Adding license.tar.gz to rpm-md data");
				system("cd $media_base && modifyrepo $licenseArchive repodata");
				$result = $? >> 8;
				if ($result != 0) {
					return 1;
				}
			}
		}
	}
	return 0;
}

1;
