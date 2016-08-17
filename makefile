todayview:
	cd src; xcodebuild -workspace todayview.xcworkspace -scheme todayview clean build archive -archivePath build
	cp src/build.xcarchive/Products/usr/local/bin/todayview .

install: todayview
	

clean:
	pwd
	rm -rf src/build.xcarchive
	rm -f todayview
	cd src; xcodebuild -workspace todayview.xcworkspace -scheme Pods-todayview clean
	cd src; xcodebuild -workspace todayview.xcworkspace -scheme todayview clean