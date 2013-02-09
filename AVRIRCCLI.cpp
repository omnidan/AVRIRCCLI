#include <Arduino.h>
#include <SPI.h>
#include <Ethernet.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // Mac address
IPAddress server(212,232,31,29); // Public IRC server - kif.entropynet.net - IPAddress server(212,232,31,29); // Private, local IRC server - IPAddress server(192,168,1,40);

// Local settings
IPAddress ip(192,168,1,41);
IPAddress dnss(192,168,1,40);
IPAddress gw(192,168,1,42);

// Initialise variables
EthernetClient client;
char *msg;

void setup() {
 Ethernet.begin(mac, ip, dnss, gw);
 Serial.begin(9600);
 while (!Serial) {
  ; // wait for serial port to connect. Needed for Leonardo only
 }
 
 Serial.println("booting...");
 
 // Wait for the ethernet chip to initialise
 delay(750);
 Serial.println("connecting...");
 
 // if you get a connection, report back via serial:
 if (client.connect(server, 6667)) {
  Serial.println("connected");
 } 
 else {
  // if you didn't get a connection to the server:
  Serial.println("connection failed");
 }
 
 if (client.connected()) {
  client.print("NICK arduino\r\n");
  client.print("USER arduino arduino.magic arduino :AVRIRCCLI\r\n");
 }
 
 msg = (char *)malloc(256);
 analogWrite(A0, 0);
}

void startup() {
 client.print("JOIN #lounge\r\n");
 client.print("PRIVMSG #lounge :Hi, my name is ");
 #if defined(__AVR_ATmega328P__)
 client.print("ATmega328P");
 #else
 client.print("Atmel chip");
 #endif  
 client.print("\r\n");
}

void privmsg(char *channel, char *text) {
 client.print("PRIVMSG #");
 client.print(channel);
 client.print(" :");
 client.print(text);
 client.print("\r\n");
}

void parsemsg(char *nick, char *user, char *server, char *channel, char *text) {
 if (strstr(text, "!ping") != NULL) privmsg(channel, "pong");
 if (strstr(text, "!nc") != NULL) privmsg(channel, "nobody cares mh0");
 if (strstr(text, "turn light off") != NULL) {
  analogWrite(A0, 0);
 }
 if (strstr(text, "turn light on") != NULL) {
  analogWrite(A0, 1023);
 }
 if (strstr(text, "pony") != NULL) {
  privmsg(channel, "I'm not a pony, I'm just a chip.");
 }
 if (strstr(text, "show light status") != NULL) {
  if (analogRead(A0) == 0) privmsg(channel, "The light is off.");
  else privmsg(channel, "The light is on.");
 }
 if (strstr(text, "show pin status") != NULL) {
  client.print("PRIVMSG #");
  client.print(channel);
  client.print(" :Status: ");
  client.print("A0="); client.print(analogRead(A0) * (5.0 / 1023.0)); client.print("V,");
  client.print("A1="); client.print(analogRead(A1) * (5.0 / 1023.0)); client.print("V,");
  client.print("A2="); client.print(analogRead(A2) * (5.0 / 1023.0)); client.print("V,");
  client.print("A3="); client.print(analogRead(A3) * (5.0 / 1023.0)); client.print("V,");
  client.print("A4="); client.print(analogRead(A4) * (5.0 / 1023.0)); client.print("V,");
  client.print("A5="); client.print(analogRead(A5) * (5.0 / 1023.0)); client.print("V,");
  client.print("\r\n");
 }
}

void loop() {
 if (client.available()) {
  char c = client.read();
  if (c != (char)10) { // character 10 = \n
   size_t cur_len = strlen(msg);
   if(cur_len < 254) {
    msg[cur_len] = c;
    msg[cur_len+1] = '\0';
   }
  }
  else {
   // This is a full command
   if (strstr(msg, "/MOTD") != NULL) {
    startup();
   } else if (strstr(msg, "PING") != NULL) {
    char *pch;
    pch = strtok(msg, " ");
    if ((pch != NULL) && (strcmp(pch, "PING") == 0)) {
     pch = strtok(NULL, " ");
     if (pch != NULL) {
      client.print("PONG ");
      client.print(pch);
      client.print("\r\n");
     }
    }
   } else if (strstr(msg, "PRIVMSG") != NULL) {
    char nick[32], user[33], server[64], channel[64], body[256];
    sscanf(msg, ":%31[^!]!%32[^@]@%63s PRIVMSG %63s :%255[^\n]", nick, user, server, channel, body);
    parsemsg(nick, user, server, channel, body);
   }
   msg[0] = '\0';
  }
  Serial.print(c);
 }
 
 // as long as there are bytes in the serial queue,
 // read them and send them out the socket if it's open:
 /*while (Serial.available() > 0) {
  char inChar = Serial.read();
  if (client.connected()) {
   client.print(inChar); 
  }
 }*/
 
 // if the server's disconnected, stop the client:
 if (!client.connected()) {
  Serial.println();
  Serial.println("disconnecting.");
  client.stop();
  while(true); // TODO: Retry
 }
}
