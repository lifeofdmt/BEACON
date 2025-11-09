import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:beacon/views/mobile/database_service.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
        final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
            'email',
        ]);

    User? get currentuser => firebaseAuth.currentUser;

    Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

    Future<UserCredential> signIn({
        required String email,
        required String password,
    }) async {
        return await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    }

    Future<UserCredential> createAccount({
        required String email,
        required String password,
    }) async {
        return await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    }

    Future<void> signOut() async{
        await firebaseAuth.signOut();
    }

    Future<void> resetPassword({
        required String email,
    }) async{
        await firebaseAuth.sendPasswordResetEmail(email: email);
    }

    Future<void> updateUsername({
        required String username,
    }) async {
        await currentuser!.updateDisplayName(username);
    }

    Future<void> deleteAccount({
        required String email,
        required String password,
    }) async {
        AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
        await currentuser!.reauthenticateWithCredential(credential);
        await currentuser!.delete();
        await firebaseAuth.signOut();
    }

    Future<void> updatePassword({
        required String email,
        required String password,
        required String newPassword,
    }) async
    {
        AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
        await currentuser!.reauthenticateWithCredential(credential);
        await currentuser!.updatePassword(newPassword);
    }

    Future<String?> getCurrentUsername() async {
        await currentuser?.reload();
        return currentuser?.displayName;
    }

        /// Sign in with Google and Firebase; creates user record in Realtime Database if new.
        Future<UserCredential?> signInWithGoogle() async {
            try {
                final googleUser = await _googleSignIn.signIn();
                if (googleUser == null) {
                    // User canceled
                    return null;
                }
                final googleAuth = await googleUser.authentication;
                final credential = GoogleAuthProvider.credential(
                    idToken: googleAuth.idToken,
                    accessToken: googleAuth.accessToken,
                );

                final userCred = await firebaseAuth.signInWithCredential(credential);
                final user = userCred.user;
                if (user != null) {
                    // Create user record if not exists
                    final snap = await DatabaseService().read(path: 'users/${user.uid}');
                    if (snap == null) {
                        await DatabaseService().create(path: 'users/${user.uid}', data: {
                            'displayName': user.displayName ?? user.email?.split('@').first ?? 'User',
                            'email': user.email,
                            'photoURL': user.photoURL,
                            'createdAt': DateTime.now().toIso8601String(),
                            'about': '',
                        });
                    }
                }
                return userCred;
            } on FirebaseAuthException catch (e) {
                debugPrint('Google sign-in Firebase error: ${e.code} ${e.message}');
                rethrow;
            } catch (e) {
                debugPrint('Google sign-in error: $e');
                rethrow;
            }
        }

}


