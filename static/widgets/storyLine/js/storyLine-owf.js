if(OWF.Util.isRunningInOWF()) {

    OWF.ready(function() {
        OWF.Eventing.subscribe('com.nextcentury.everest.storyLine.events', function (sender, msg, channel) {
        	var message = JSON.parse(msg);
        	if(message.configs){

        		var configs = message.configs;

                if(configs.eraseData){
                    app.clearEvents();
                } 

                if(configs.setDeduceLayout != undefined){
                    app.setDeduceLayout(configs.setDeduceLayout);
                }

        		if(configs.bandInfos){
        			app.changeLayout(configs.bandInfos);
        		}
        		
                if(configs.maxClasses){
                    app.setMaxClasses(configs.maxClasses);
                }
        	}
            if(message.events){
                var events = message.events;
                app.addEvents(events);
            }
            // added to center the date when a reminder is selected.
            if(message.dueDate){
                app.centerTimeLine(message.dueDate);
            }


        });

        OWF.notifyWidgetReady();
    });
}
