# O R8 vem ligado no release do Flutter e tira as classes que acha que ninguém usa.
# O tflite_flutter chama o TFLite pela biblioteca nativa (libtensorflowlite_jni.so),
# então pelo lado Java parece que ninguém usa essas classes. Mantenho todas pra não
# arriscar o modelo não carregar no APK de release.
-keep class org.tensorflow.lite.** { *; }

# O LiteRT traz o delegate de GPU, que cita classes que não vêm no pacote. Sem isso
# o R8 para o build com "Missing class". Eu não uso GPU, só CPU.
-dontwarn org.tensorflow.lite.**
