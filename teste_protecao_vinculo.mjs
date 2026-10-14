
import { initializeApp } from 'firebase/app';
import {
    getAuth,
    connectAuthEmulator,
    signInWithEmailAndPassword
} from 'firebase/auth';
import {
    getFirestore,
    connectFirestoreEmulator,
    doc,
    setDoc,
    updateDoc,
    deleteDoc,
    getDoc
} from 'firebase/firestore';

const app = initializeApp({
    apiKey: 'fake-api-key',
    projectId: 'mindful-tcc'
});

const auth = getAuth(app);
connectAuthEmulator(auth, 'http://127.0.0.1:9099', {
    disableWarnings: true
});

const db = getFirestore(app);
connectFirestoreEmulator(db, '127.0.0.1', 8080);

await signInWithEmailAndPassword(
    auth,
    'vinculo.tcc@example.com',
    'TesteVinculo2026!'
);

const ref = doc(db, 'solicitacoes_vinculo_demo', auth.currentUser.uid);

const testes = [
    ['Leitura', () => getDoc(ref)],
    ['Criação/sobrescrita', () => setDoc(ref, { estado: 'confirmado' })],
    ['Atualização', () => updateDoc(ref, { estado: 'confirmado' })],
    ['Exclusão', () => deleteDoc(ref)]
];

let aprovados = 0;

for (const [nome, executar] of testes) {
    try {
        await executar();
        console.log(`FALHA: ${nome} foi permitida`);
    } catch (erro) {
        if (erro.code === 'permission-denied') {
            aprovados++;
            console.log(`APROVADO: ${nome} bloqueada`);
        } else {
            console.log(`INCONCLUSIVO: ${nome}: ${erro.code || erro.message}`);
        }
    }
}

console.log(`Resultado: ${aprovados}/4`);
process.exit(aprovados === 4 ? 0 : 1);
