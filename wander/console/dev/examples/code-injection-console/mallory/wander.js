const wander = { // eslint-disable-line no-unused-vars
  consoles: ['https://example.com/wander/'],
  get pages () {
    console.log('Mallory executes code')
    try {
      console.log('Mallory reads cookie:', document.cookie)
    } catch (e) {
      console.log('Mallory failed to read cookie:', e)
    }
  }
}
