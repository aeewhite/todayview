todayview:
	cd src; xcodebuild -workspace todayview.xcworkspace -scheme todayview -verbose build archive -archivePath build > /dev/null
	cp src/build.xcarchive/Products/usr/local/bin/todayview .

install: todayview
	cp todayview /usr/local/bin

clean:
	rm -rf src/build.xcarchive
	rm -f todayview
	cd src; xcodebuild -workspace todayview.xcworkspace -scheme Pods-todayview clean
	cd src; xcodebuild -workspace todayview.xcworkspace -scheme todayview clean