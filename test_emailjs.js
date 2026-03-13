

async function testEmail() {
  const url = 'https://api.emailjs.com/api/v1.0/email/send';
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        service_id: 'service_jr8le7c',
        template_id: 'template_xj2f02b',
        user_id: 'AL_u8EiAxaurwckgg',
        template_params: {
          to_email: 'thaweenilukshan@gmail.com',
          reset_link: 'http://localhost:3000/password_reset_web/index.html',
        }
      })
    });
    const text = await response.text();
    console.log('Status:', response.status);
    console.log('Response:', text);
  } catch (err) {
    console.error('Error:', err);
  }
}

testEmail();
