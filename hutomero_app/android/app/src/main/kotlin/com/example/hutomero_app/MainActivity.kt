package com.example.hutomero_app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "hutomero/notifications"
	private val NOTIF_CHANNEL_ID = "warnings_channel"
	private var pending: MethodCall? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"init" -> {
					createNotificationChannel()
					result.success(true)
				}
				"show" -> {
					val args = call.arguments as? Map<*, *>
					val id = (args?.get("id") as? Int) ?: 0
					val title = args?.get("title") as? String ?: ""
					val body = args?.get("body") as? String ?: ""

					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
						ActivityCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
						// request permission and store pending notification
						pending = call
						ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
						result.success(false)
					} else {
						showNotification(id, title, body)
						result.success(true)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun createNotificationChannel() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val name = "Warnings"
			val descriptionText = "Notifications about warning changes"
			val importance = NotificationManager.IMPORTANCE_DEFAULT
			val channel = NotificationChannel(NOTIF_CHANNEL_ID, name, importance)
			channel.description = descriptionText
			val notificationManager: NotificationManager = getSystemService(NotificationManager::class.java)
			notificationManager.createNotificationChannel(channel)
		}
	}

	private fun showNotification(id: Int, title: String, body: String) {
		val builder = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
			.setSmallIcon(android.R.drawable.ic_dialog_alert)
			.setContentTitle(title)
			.setContentText(body)
			.setPriority(NotificationCompat.PRIORITY_DEFAULT)

		with(NotificationManagerCompat.from(this)) {
			notify(id, builder.build())
		}
	}

	override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode == 1001) {
			if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
				// show pending notification if any
				pending?.let {
					val args = it.arguments as? Map<*, *>
					val id = (args?.get("id") as? Int) ?: 0
					val title = args?.get("title") as? String ?: ""
					val body = args?.get("body") as? String ?: ""
					showNotification(id, title, body)
				}
			}
			pending = null
		}
	}
}
