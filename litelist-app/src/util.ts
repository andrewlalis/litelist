export function stringToColor(str: string, saturation: number = 100, lightness: number = 75): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        hash = str.charCodeAt(i) + ((hash << 5) - hash);
        hash = hash & hash;
    }
    return `hsl(${(hash % 360)}, ${saturation}%, ${lightness}%)`;
}

export function parseJwt (token: string): any {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(window.atob(base64).split('').map(function(c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join(''));
    return JSON.parse(jsonPayload);
}

export function getUnixTime(): number {
    return Math.floor(new Date().getTime() / 1000)
}

export function getSecondsTilExpire(token: string): number {
    const now = getUnixTime()
    const decoded = parseJwt(token)
    return decoded.exp - now
}
