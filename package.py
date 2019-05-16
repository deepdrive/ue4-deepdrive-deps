#!/usr/bin/env python3
from ue4helpers import CacheUtils, FilesystemUtils, ProjectPackager, UnrealUtils
from os.path import abspath, dirname, join
import argparse, shutil, sys


# The base URL for the Amazon S3 bucket from which we download any required files
S3_BASEURL = 'https://s3-us-west-1.amazonaws.com/deepdrive/'

# The version string and archive filename for the Substance plugin that we require
SUBSTANCE_VERSION = '4.21.0.31'
SUBSTANCE_ARCHIVE = 'Substance-{}-Desktop.zip'.format(SUBSTANCE_VERSION)

# The version string and archive filename for the UnrealEnginePython plugin that we require
UEPY_VERSION = '20190128'
UEPY_ARCHIVE = 'UnrealEnginePython-{}-Linux.zip'.format(UEPY_VERSION)


def package(root):
    
    # Install our dependency plugins
    install_plugins(root)
    
    # Create our project packager
    packager = ProjectPackager(
        root=root,
        version=FilesystemUtils.read(join(root, 'Content', 'Data', 'VERSION')),
        archive='{name}-{platform}-{version}',
    )
    
    # Clean any previous build artifacts
    packager.clean()
    
    # Package the project
    packager.package(args=['Development'])
    
    # Compress the packaged distribution
    archive = packager.archive()
    
    # Rename archive to format used on S3
    archive = shutil.move(archive, reformat_name(archive))
    
    # The generated archive will be uploaded to Amazon S3 by the wrapper CI script
    print('Created compressed archive "{}".'.format(archive))


def install_plugins(root):
    
    # Download and extract the prebuilt binaries for the Substance plugin
    print('Downloading and extracting the prebuilt Substance plugin...', flush=True, file=sys.stderr)
    UnrealUtils.install_plugin(
        
        # Use our cached copy if we have it, otherwise download it from S3
        CacheUtils.select_cheapest([
            join(root, 'Packaging', SUBSTANCE_ARCHIVE),
            S3_BASEURL + SUBSTANCE_ARCHIVE
        ]),
        
        # Install the plugin to the Engine's "Marketplace" plugins subdirectory
        'Substance',
        prefix='Marketplace'
    )
    
    # Download and extract the prebuilt binaries for  the UnrealEnginePython plugin
    print('Downloading and extracting the prebuilt UnrealEnginePython plugin...', flush=True, file=sys.stderr)
    UnrealUtils.install_plugin(
        
        # Use our cached copy if we have it, otherwise download it from S3
        CacheUtils.select_cheapest([
            join(root, 'Packaging', UEPY_ARCHIVE),
            S3_BASEURL + UEPY_ARCHIVE
        ]),
        
        # Install the plugin to the Engine's root plugins directory
        'UnrealEnginePython'
    )


def reformat_name(archive_name):
    name, platform, version_and_ext = archive_name.split('-')
    name = name.lower() + '-sim'
    platform = platform.lower()
    ret = '-'.join([name, platform, version_and_ext])
    return ret


if __name__ == '__main__':
    
    # Compute the absolute path to the root of the repository
    root = dirname(dirname(abspath(__file__)))
    
    # Parse any supplied command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--plugins-only', action='store_true', help='Only download and install plugins, skip packaging')
    args = parser.parse_args()
    
    # Determine if we are performing packaging or just installing plugins
    if args.plugins_only == True:
        install_plugins(root)
    else:
        package(root)
