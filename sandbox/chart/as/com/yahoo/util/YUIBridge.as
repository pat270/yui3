package com.yahoo.util
{
	import flash.display.Stage;
	import flash.display.DisplayObject;
	import flash.external.ExternalInterface;
	import flash.utils.getDefinitionByName;
	import com.adobe.serialization.json.JSON;

	public class YUIBridge extends Object
	{
		/**
		 * Constructor
		 */
		public function YUIBridge(stage:Stage)
		{
			this._stage = stage;
			this.initializeBridge();
		}
		
		/**
		 * @private
		 */
		private var _classHash:Object = {};

		/**
		 * @private
		 */
		private var _stage:Stage;

		/**
		 * @private 
		 * Storage for flashvars
		 */
		private var _flashvars:Object;
		
		/**
		 * Reference to the loaderInfo parameters of the application
		 */
		public function get flashvars():Object
		{
			return this._flashvars;
		}
		
		/**
		 * @private
		 */
		private var _jsHandler:String;
		
		/**
		 * @private
		 */
		private var _swfID:String;
		
		/**
		 * @private
		 */
		private var _yId:String;
		
		/**
		 * @private
		 */
		private var _instances:Object = {};

		/**
		 * Performs a function on an object.
		 * @param instanceId Reference to the object in which the method will be called
		 * @param method Reference to the function that will be called
		 * @param params Arguments to passed to the function
		 */
		public function applyMethod(instanceId:String, method:String, params:Array = null):*
		{	
			if(params) params = this.parseInstances(params);
			return (this._instances[instanceId][method] as Function).apply(this._instances[instanceId], params);
		}

		/**
		 * Creates an instance of a specified class.
		 */
		public function createInstance(instanceId:String, className:String, constructorArguments:Array = null) : void 
		{
			var cA:Array = constructorArguments ? constructorArguments : [];
			var classReference:Class = this.getClass(className) as Class;
			var instance:Object;
			
			cA = this.parseInstances(cA);

			switch (cA.length) 
			{
				default: instance = new classReference(); break;
				case 1: instance = new classReference(cA[0]); break;
				case 2: instance = new classReference(cA[0], cA[1]); break;
				case 3: instance = new classReference(cA[0], cA[1], cA[2]); break;
				case 4: instance = new classReference(cA[0], cA[1], cA[2], cA[3]); break;
				case 5: instance = new classReference(cA[0], cA[1], cA[2], cA[3], cA[4]); break;
				case 6: instance = new classReference(cA[0], cA[1], cA[2], cA[3], cA[4], cA[5]); break;
				case 7: instance = new classReference(cA[0], cA[1], cA[2], cA[3], cA[4], cA[5], cA[6]); break;
				case 8: instance = new classReference(cA[0], cA[1], cA[2], cA[3], cA[4], cA[5], cA[6], cA[7]); break;
				case 9: instance = new classReference(cA[0], cA[1], cA[2], cA[3], cA[4], cA[5], cA[6], cA[7], cA[8]); break;
				case 10: instance = new classReference(cA[0], cA[1], cA[2], cA[3], cA[4], cA[5], cA[6], cA[7], cA[8], cA[9]); break;
				case 11: instance = new classReference(cA[0], cA[1], cA[2], cA[3], cA[4], cA[5], cA[6], cA[7], cA[8], cA[9], cA[10]); break;
				case 12: instance = new classReference(cA[0], cA[1], cA[2], cA[3], cA[4], cA[5], cA[6], cA[7], cA[8], cA[9], cA[10], cA[11]); break;
				case 13: instance = new classReference(cA[0], cA[1], cA[2], cA[3], cA[4], cA[5], cA[6], cA[7], cA[8], cA[9], cA[10], cA[11], cA[12]); break;
			}
			_instances[instanceId] = instance;	
		}

		/**
		 * Returns a class instance based on a key value
		 */
		public function getInstance(instanceId:String) : * 
		{
			if (_instances.hasOwnProperty(instanceId)) 
			{
				return _instances[instanceId];
			}
			else 
			{
				return null;
			}
		}
	
		/**
		 * Adds an object to the hash of instances
		 */
		public function setInstance(instanceId:String, value:*):void
		{
			this._instances[instanceId] = value;
		}

		/**
		 * Exposes a method to the host DOM
		 */
		public function exposeMethod(instanceId:String, methodName:String, exposedName:String = "") : void 
		{
			exposedName == "" ? exposedName = methodName : exposedName = exposedName;
			
			if (_instances[instanceId] && ExternalInterface.available) 
			{
				ExternalInterface.addCallback(exposedName, _instances[instanceId][methodName]);
			}
		}
		
		/**
		 * Returns the value of a class property
		 * 
		 * @param instanceId key used to look up the value of a class instance
		 * @param propertyName the name of the property whose value is protected
		 */
		public function getProperty (instanceId:String, propertyName:String) : Object 
		{
			if (_instances[instanceId] && _instances[instanceId].hasOwnProperty(propertyName)) 
			{
				return _instances[instanceId][propertyName];
			}
			else 
			{
				return null;
			}
		}
		
		/**
		 * Sets the value for a property on a class instance
		 *
		 * @param instanceId key used to look up the class instance whose property is to be changed
		 * @param propertyName name of the property to be changed
		 * @propertyValue value to be set
		 */
		public function setProperty (instanceId:String, propertyName:String, propertyValue:Object) : void 
		{
			if (_instances.hasOwnProperty(instanceId) && _instances[instanceId].hasOwnProperty(propertyName)) 
			{
				_instances[instanceId][propertyName] = propertyValue;
			}
		}

		/**
		 * Exposes methods to the host DOM
		 */
		public function addCallbacks (callbacks:Object) : void 
		{
			if (ExternalInterface.available) 
			{
				for (var callback:String in callbacks) 
				{
					ExternalInterface.addCallback(callback, callbacks[callback]);
				}
				sendEvent({type:"swfReady"});
			}
		}

		/**
		 * Dispatches events to the host DOM
		 */
		public function sendEvent (evt:Object) : void 
		{
			if (ExternalInterface.available) 
			{
				ExternalInterface.call("YUI.applyTo", _yId, _jsHandler, [_swfID, evt]);
			}
		}

		/**
		 * Adds classes to the class hash
		 */
		public function addClasses(value:Object):void
		{
			for(var i:String in value) this._classHash[i] = value[i];
		}

		/**
		 * @private (protected)
		 */
		protected function initializeBridge():void
		{
			if(this._stage.loaderInfo.parameters) this._flashvars = this._stage.loaderInfo.parameters;

			if (this._flashvars.hasOwnProperty("yId") && this._flashvars.hasOwnProperty("YUIBridgeCallback") && this._flashvars.hasOwnProperty("YUISwfId") && ExternalInterface.available) 
			{
				_jsHandler = this._flashvars["YUIBridgeCallback"];
				_swfID = this._flashvars["YUISwfId"];
				_yId = this._flashvars["yId"];
			}
			
			ExternalInterface.addCallback("createInstance", createInstance);
			ExternalInterface.addCallback("applyMethod", applyMethod);
			ExternalInterface.addCallback("exposeMethod", exposeMethod);
			ExternalInterface.addCallback("getProperty", getProperty);
			ExternalInterface.addCallback("setProperty", setProperty);
		}

		/**
		 * @private
		 */
		private function parseInstances(args:Array):Array
		{
			var first:String,
				i:int,
				len:int = args.length,
				arg:String;
			for (i = 0; i < len; ++i) 
			{
				if (args[i] is String)
				{
					arg = args[i] as String;
					first = arg.substr(0, 1);
					if(first == "$") 
					{
						args[i] = getInstance(arg.substr(1));
					}
					else if(first == "[" || first == "{")
					{
						args[i] = JSON.decode(arg); 
					}
				}
			}
			return args;
		}
		
		/**
		 * @private
		 */
		private function getClass(value:String):Class
		{
			if(this._classHash.hasOwnProperty(value)) return this._classHash[value] as Class;
			return getDefinitionByName(value) as Class;
		}
	}
}
