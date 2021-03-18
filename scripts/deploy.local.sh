#!/bin/sh
echo "[ LOCAL ] | START"
echo "[ LOCAL ] | SCP BUILD"
scp -r $TRAVIS_BUILD_DIR/build $cpanel_ssh_user@$domain:/home1/$cpanel_ssh_user/public_html

echo "[ LOCAL ] | SCP DEPLOY REMOTE FILE"
scp -r $TRAVIS_BUILD_DIR/scripts/deploy.remote.sh $cpanel_ssh_user@$domain:/home1/$cpanel_ssh_user

echo "[ LOCAL ] | EXECUTE DEPLOY REMOTE FILE"
ssh $cpanel_ssh_user@$domain 'chmod 777 deploy.remote.sh'
ssh $cpanel_ssh_user@$domain 'sh deploy.remote.sh'
echo "[ LOCAL ] | FINISH"
