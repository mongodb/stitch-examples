// Change this to be your bucket name.
const BucketName = 'osschat';

function createAssetInformation({ isVideo }) {
  const now = new Date();
  const isoString = now.toISOString();
  const date = isoString.split('T')[0]; // aka 2017-02-10
  const fileExtension = isVideo ? 'mov' : 'jpg';
  const fileName = `${date}/${isoString}.${fileExtension}`;

  const contentType = isVideo ? 'video/quicktime' : 'image/jpg';
  return {
    fileName,
    contentType,
  };
}

export default (async function uploadAsset(
  { localPath, baasClient, isVideo = false },
) {
  const { fileName, contentType } = createAssetInformation({ isVideo });

  const signPolicyResponse = await baasClient.executePipeline([
    {
      service: 's31',
      action: 'signPolicy',
      args: {
        bucket: BucketName,
        key: fileName,
        acl: 'public-read',
        contentType,
      },
    },
  ]);

  const signResponse = signPolicyResponse.result[0];

  const data = new FormData();
  data.append('AWSAccessKeyId', signResponse.accessKeyId);
  data.append('key', fileName);
  data.append('bucket', BucketName);
  data.append('acl', 'public-read');
  data.append('policy', signResponse.policy);
  data.append('signature', signResponse.signature);
  data.append('Content-Type', contentType);
  data.append('file', {
    uri: localPath,
    name: fileName,
    type: contentType,
  });

  const fetchResponse = await fetch(`https://${BucketName}.s3.amazonaws.com/`, {
    method: 'POST',
    body: data,
  });

  if (!fetchResponse.ok) {
    throw new Error(await fetchResponse.text());
  }

  const assetUrl = fetchResponse.headers.map.location[0];

  return assetUrl;
});
