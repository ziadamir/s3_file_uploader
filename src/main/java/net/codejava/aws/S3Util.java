package net.codejava.aws;

import java.io.IOException;
import java.io.InputStream;

import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.core.waiters.WaiterResponse;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.waiters.S3Waiter;




public class S3Util {
	
	private static final String BUCKET = "s3-upload-input-bucket";
	
	public static void uploadFile(String fileName, InputStream inputStream) 
			throws S3Exception, AwsServiceException, SdkClientException, IOException {
		S3Client client = S3Client.builder().build();



		try {           

			S3Waiter waiter = client.waiter();
					 
			CreateBucketRequest request = CreateBucketRequest.builder().bucket(BUCKET).build();
			 
			client.createBucket(request);
			 
			HeadBucketRequest requestWait = HeadBucketRequest.builder().bucket(BUCKET).build();
			 
			waiter.waitUntilBucketExists(requestWait);
					 
			System.out.println("Bucket " + BUCKET + " is ready.");
			 
			// run code that depends on the newly created bucket
                 
            }
    	 catch (AwsServiceException e) {
             
            System.out.println(e.getMessage());
             
        }
		
		PutObjectRequest request = PutObjectRequest.builder()
										.bucket(BUCKET) 
										.key(fileName)
										.acl("public-read")
										.build();
		
		client.putObject(request, 
				RequestBody.fromInputStream(inputStream, inputStream.available()));
		
		S3Waiter waiter = client.waiter();
		HeadObjectRequest waitRequest = HeadObjectRequest.builder()
											.bucket(BUCKET)
											.key(fileName)
											.build();
		
		WaiterResponse<HeadObjectResponse> waitResponse = waiter.waitUntilObjectExists(waitRequest);
		
		waitResponse.matched().response().ifPresent(x -> {
			// run custom code that should be executed after the upload file exists
		});
	}
}
