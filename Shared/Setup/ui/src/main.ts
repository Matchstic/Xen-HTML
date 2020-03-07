import Vue from 'vue';
import App from './App.vue';

// @ts-ignore
import resize from 'vue-resize-directive';
// @ts-ignore
import VueParticles from 'vue-particles';

Vue.config.productionTip = false;
Vue.directive(resize);
Vue.use(VueParticles);

new Vue({
  render: h => h(App),
}).$mount('#app');

(window as any).onerror = (error: any) => {
  // @ts-ignore
  window.webkit.messageHandlers.xenhtml.postMessage('error');
};